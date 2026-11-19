/**
	Destiny: the package supplier for Destiny-Org/packages.

	All Destiny packages live in one GitHub repository, one folder per
	package. `index.json` at the top of its `main` branch lists them:

	---
	{ "repository": "https://github.com/Destiny-Org/packages",
	  "packages": [ { "name": "vibe-d", "path": "vibe-d",
	                  "upstreamVersion": "0.10.5", "tag": "vibe-d/0.10.5", ... } ] }
	---

	A package may instead list several versions:
	`"versions": [ { "version": "0.10.5", "tag": "vibe-d/0.10.5" }, ... ]`.

	A version is fetched with a shallow, sparse git clone of the repository at
	its tag that checks out only the package's folder, so a download never
	includes the other packages.
*/
module dub.packagesuppliers.destiny;

import dub.packagesuppliers.packagesupplier;

/// URL scheme that selects this supplier: `destiny+https://github.com/<owner>/<repo>`
enum destinySupplierScheme = "destiny+";

/// The default (and only built-in) package source of DES.
enum defaultDestinyPackagesUrl = "destiny+https://github.com/Destiny-Org/packages";

class DestinyPackageSupplier : PackageSupplier
{
	import dub.internal.logging;
	import dub.internal.utils : retryDownload;
	import dub.internal.vibecompat.data.json : parseJsonString;
	import dub.internal.vibecompat.inet.url : URL;

	private {
		string m_repo;        // https://github.com/<owner>/<repo>
		string m_indexUrl;    // raw URL of index.json on main
		bool m_indexLoaded;
		Json[string] m_packages;           // name -> index entry
		string[string] m_checkouts;        // tag -> local folder of the package
	}

	/// `url`: `https://github.com/<owner>/<repo>` (without the scheme prefix)
	this(string url)
	{
		import std.algorithm.searching : endsWith, startsWith;
		import std.exception : enforce;
		import std.string : chomp;

		m_repo = url.chomp("/").chomp(".git");
		if (m_repo.startsWith("file://"))
		{
			// a local clone of the packages repository (for testing and offline use)
			m_indexUrl = m_repo;
			return;
		}
		enforce(m_repo.startsWith("https://github.com/"),
			"Destiny packages must be hosted on GitHub: " ~ url);
		m_indexUrl = "https://raw.githubusercontent.com/"
			~ m_repo["https://github.com/".length .. $] ~ "/main/index.json";
	}

	override @property string description()
	{
		return "Destiny packages at " ~ m_repo;
	}

	override Version[] getVersions(in PackageName name)
	{
		import std.algorithm.sorting : sort;
		Version[] ret;
		foreach (v; versionsOf(name))
			ret ~= Version(v["version"].get!string);
		ret.sort();
		return ret;
	}

	override ubyte[] fetchPackage(in PackageName name, in VersionRange dep, bool pre_release)
	{
		auto best = best(name, dep, pre_release);
		if (best.type == Json.Type.null_)
			return null;
		return zipFolder(checkout(name, best), name.main.toString());
	}

	override Json fetchPackageRecipe(in PackageName name, in VersionRange dep, bool pre_release)
	{
		import dub.recipe.io : parsePackageRecipe;
		import dub.recipe.json : toJson;
		import std.file : exists, readText;
		import std.path : buildPath;

		auto best = best(name, dep, pre_release);
		if (best.type == Json.Type.null_)
			return best;
		const dir = checkout(name, best);
		foreach (file; ["dub.json", "dub.sdl", "package.json"])
		{
			const path = buildPath(dir, file);
			if (!exists(path))
				continue;
			auto recipe = parsePackageRecipe(readText(path), path,
				PackageName.init, name.main.toString());
			auto json = recipe.toJson();
			json["version"] = best["version"];
			return json;
		}
		throw new Exception("Package " ~ name.main.toString() ~ " has no dub.json or dub.sdl at "
			~ best["tag"].get!string);
	}

	override SearchResult[] searchPackages(string query)
	{
		import std.algorithm.searching : canFind;
		import std.uni : toLower;

		loadIndex();
		SearchResult[] ret;
		foreach (n, entry; m_packages)
			if (n.toLower.canFind(query.toLower))
			{
				auto vers = versionsOf(PackageName(n));
				ret ~= SearchResult(n, entry["description"].opt!string,
					vers.length ? vers[$ - 1]["version"].get!string : "");
			}
		return ret;
	}

	private void loadIndex()
	{
		import std.exception : enforce;
		if (m_indexLoaded)
			return;
		import std.algorithm.searching : startsWith;
		import std.process : execute;
		Json json;
		if (m_repo.startsWith("file://"))
		{
			// index.json as committed on main
			auto r = execute(["git", "-C", m_repo["file://".length .. $], "show", "main:index.json"]);
			enforce(r.status == 0, "cannot read index.json from " ~ m_repo ~ ": " ~ r.output);
			json = parseJsonString(r.output, m_repo ~ "/index.json");
		}
		else
		{
			logDebug("Downloading the Destiny package index %s", m_indexUrl);
			json = parseJsonString(cast(string) retryDownload(URL(m_indexUrl)), m_indexUrl);
		}
		foreach (entry; json["packages"])
			m_packages[entry["name"].get!string] = entry;
		m_indexLoaded = true;
	}

	/// The versions of a package, each `{ "version": ..., "tag": ..., "path": ... }`
	private Json[] versionsOf(in PackageName name)
	{
		loadIndex();
		auto entry = name.main.toString() in m_packages;
		if (!entry)
			return null;
		const path = (*entry)["path"].opt!string(name.main.toString());
		Json[] ret;
		if ((*entry)["versions"].type == Json.Type.array)
		{
			foreach (v; (*entry)["versions"])
			{
				auto j = Json.emptyObject;
				j["version"] = v["version"];
				j["tag"] = v["tag"];
				j["path"] = v["path"].opt!string(path);
				ret ~= j;
			}
		}
		else
		{
			auto j = Json.emptyObject;
			j["version"] = (*entry)["upstreamVersion"];
			j["tag"] = (*entry)["tag"];
			j["path"] = path;
			ret ~= j;
		}
		return ret;
	}

	private Json best(in PackageName name, in VersionRange dep, bool pre_release)
	{
		auto vers = versionsOf(name);
		if (!vers.length)
			return Json(null);
		auto md = Json.emptyObject;
		md["versions"] = Json(vers);
		return getBestPackage(md, name, dep, pre_release);
	}

	/// Checks out only the package's folder at its tag; returns that folder.
	private string checkout(in PackageName name, Json ver)
	{
		import std.algorithm.searching : startsWith;
		import std.exception : enforce;
		import std.file : exists, mkdirRecurse, tempDir;
		import std.format : format;
		import std.path : buildPath;
		import std.process : execute;
		import std.random : uniform;

		const tag = ver["tag"].get!string;
		const path = ver["path"].get!string;
		if (auto dir = tag in m_checkouts)
			return *dir;

		const work = buildPath(tempDir, "des-packages-%s-%s".format(name.main, uniform(0, uint.max)));
		mkdirRecurse(work);
		scope (failure) removeCheckout(work);
		tempCheckouts ~= work; // removed when DES exits (see the module destructor)
		logInfo("Fetching", Color.light_green, "%s %s from %s", name.main, ver["version"].get!string, m_repo);

		auto run(string[] args)
		{
			auto r = execute(args, ["GIT_TERMINAL_PROMPT": "0"]);
			enforce(r.status == 0, "%s failed: %s".format(args[0 .. 2], r.output));
		}
		const src = m_repo.startsWith("file://") ? m_repo : m_repo ~ ".git";
		run(["git", "clone", "--quiet", "--depth", "1", "--filter=blob:none", "--sparse",
			"--branch", tag, src, work]);
		run(["git", "-C", work, "sparse-checkout", "set", "--no-cone", "/" ~ path ~ "/"]);

		const dir = buildPath(work, path);
		enforce(exists(dir), "Tag %s of %s has no folder %s".format(tag, m_repo, path));
		m_checkouts[tag] = dir;
		return dir;
	}

	/// Deletes a temporary checkout, ignoring errors (it is only a cache).
	private static void removeCheckout(string work) nothrow
	{
		import std.file : exists, rmdirRecurse;
		try { if (exists(work)) rmdirRecurse(work); }
		catch (Exception) {}
	}

	/// Zips `dir` with its contents under `root/`, the layout DES extracts.
	private static ubyte[] zipFolder(string dir, string root)
	{
		import std.algorithm.searching : canFind;
		import std.file : dirEntries, isFile, read, SpanMode;
		import std.path : relativePath;
		import std.string : replace;
		import std.datetime : SysTimeToDosFileTime;
		import std.zip : ArchiveMember, CompressionMethod, ZipArchive;

		auto zip = new ZipArchive;
		foreach (e; dirEntries(dir, SpanMode.depth))
		{
			if (!e.isFile)
				continue;
			const rel = relativePath(e.name, dir).replace("\\", "/");
			if (rel.canFind(".git/"))
				continue;
			auto m = new ArchiveMember;
			m.name = root ~ "/" ~ rel;
			m.expandedData = cast(ubyte[]) read(e.name);
			m.time = SysTimeToDosFileTime(e.timeLastModified); // DES rejects a zero DOS time
			m.compressionMethod = CompressionMethod.deflate;
			zip.addMember(m);
		}
		return cast(ubyte[]) zip.build();
	}
}

/// Temporary checkouts made by this process; each is a sparse clone of the
/// packages repository in the temp folder.
private string[] tempCheckouts;

static ~this()
{
	foreach (work; tempCheckouts)
		DestinyPackageSupplier.removeCheckout(work);
	tempCheckouts = null;
}
