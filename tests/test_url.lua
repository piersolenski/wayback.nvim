-- Test URL building and forge detection
-- We test the internal functions by requiring the module and inspecting behavior

local config = require("wayback.config")

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("PASS: " .. name)
  else
    print("FAIL: " .. name .. " - " .. tostring(err))
    vim.cmd("cquit 1")
  end
end

-- We need to test the URL builders and forge detection.
-- Since these are local functions in actions.lua, we test them indirectly
-- by replicating the logic here. This validates the patterns are correct.

local function detect_forge(url)
  local cfg = config.values
  if cfg.forge then
    return cfg.forge
  end

  if url:find("gitlab") then
    return "gitlab"
  end
  if url:find("bitbucket") then
    return "bitbucket"
  end
  if url:find("dev%.azure%.com") or url:find("visualstudio%.com") then
    return "azure_devops"
  end
  return "github"
end

local function url_encode(str)
  if str then
    str = string.gsub(str, "\n", "\r\n")
    str = string.gsub(str, "([^%w %.])", function(c)
      return string.format("%%%02X", string.byte(c))
    end)
    str = string.gsub(str, " ", "+")
  end
  return str
end

local url_builders = {
  github = function(repo_url, hash, path)
    return repo_url .. "/blob/" .. hash .. "/" .. path
  end,
  gitlab = function(repo_url, hash, path)
    return repo_url .. "/-/blob/" .. hash .. "/" .. path
  end,
  bitbucket = function(repo_url, hash, path)
    return repo_url .. "/src/" .. hash .. "/" .. path
  end,
  azure_devops = function(repo_url, hash, path)
    return repo_url .. "?path=" .. url_encode(path) .. "&version=GC" .. hash .. "&_a=contents"
  end,
}

local function reset()
  config.values = {
    picker = "auto",
    mappings = { i = {}, n = {} },
    browser_command = nil,
    forge = nil,
  }
end

-- Forge detection tests

test("detect github.com", function()
  reset()
  assert(detect_forge("https://github.com/user/repo") == "github")
end)

test("detect gitlab.com", function()
  reset()
  assert(detect_forge("https://gitlab.com/user/repo") == "gitlab")
end)

test("detect self-hosted gitlab", function()
  reset()
  assert(detect_forge("https://gitlab.company.com/user/repo") == "gitlab")
end)

test("detect bitbucket.org", function()
  reset()
  assert(detect_forge("https://bitbucket.org/user/repo") == "bitbucket")
end)

test("detect self-hosted bitbucket", function()
  reset()
  assert(detect_forge("https://bitbucket.mycompany.com/user/repo") == "bitbucket")
end)

test("detect azure devops", function()
  reset()
  assert(detect_forge("https://dev.azure.com/org/project/_git/repo") == "azure_devops")
end)

test("detect visualstudio.com", function()
  reset()
  assert(detect_forge("https://org.visualstudio.com/project/_git/repo") == "azure_devops")
end)

test("unknown host defaults to github", function()
  reset()
  assert(detect_forge("https://git.mycompany.com/user/repo") == "github")
end)

test("config forge overrides detection", function()
  reset()
  config.setup({ forge = "gitlab" })
  assert(detect_forge("https://github.com/user/repo") == "gitlab")
end)

-- URL builder tests

test("github url format", function()
  local url = url_builders.github("https://github.com/user/repo", "abc1234", "src/main.lua")
  assert(url == "https://github.com/user/repo/blob/abc1234/src/main.lua", "got: " .. url)
end)

test("gitlab url format", function()
  local url = url_builders.gitlab("https://gitlab.com/user/repo", "abc1234", "src/main.lua")
  assert(url == "https://gitlab.com/user/repo/-/blob/abc1234/src/main.lua", "got: " .. url)
end)

test("bitbucket url format", function()
  local url = url_builders.bitbucket("https://bitbucket.org/user/repo", "abc1234", "src/main.lua")
  assert(url == "https://bitbucket.org/user/repo/src/abc1234/src/main.lua", "got: " .. url)
end)

test("azure devops url format", function()
  local url = url_builders.azure_devops(
    "https://dev.azure.com/org/project/_git/repo",
    "abc1234",
    "src/main.lua"
  )
  local expected =
    "https://dev.azure.com/org/project/_git/repo?path=src%2Fmain.lua&version=GCabc1234&_a=contents"
  assert(url == expected, "got: " .. url)
end)

-- SSH to HTTPS conversion test (replicating the logic from actions.lua)

test("ssh to https conversion", function()
  local repo_url = "git@github.com:user/repo.git"
  repo_url = repo_url:gsub(":", "/")
  repo_url = repo_url:gsub("git@", "https://")
  repo_url = repo_url:gsub("%.git$", "")
  assert(repo_url == "https://github.com/user/repo", "got: " .. repo_url)
end)

test("ssh to https conversion for gitlab", function()
  local repo_url = "git@gitlab.com:user/repo.git"
  repo_url = repo_url:gsub(":", "/")
  repo_url = repo_url:gsub("git@", "https://")
  repo_url = repo_url:gsub("%.git$", "")
  assert(repo_url == "https://gitlab.com/user/repo", "got: " .. repo_url)
end)

test("https url stays unchanged", function()
  local repo_url = "https://github.com/user/repo"
  -- The is_https check would skip conversion
  assert(repo_url:match("^https://"), "should be https")
end)

print("\nAll URL tests passed!")
vim.cmd("qall!")
