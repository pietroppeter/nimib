when defined(nimibBookEmptyPage):
  import nimib
  nbInit
nbDoc.context["language"] = "en-us"
nbDoc.context["default_theme"] = "light"
nbDoc.context["description"] = "example mdbook with nimib"
nbDoc.context["favicon_whale"] = """<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2280%22>🐳</text></svg>">"""
nbDoc.context["path_to_root"] = nbDoc.context["home_path"].castStr & "/" # I probably should make sure to have / at the end
nbDoc.context["preferred_dark_theme"] = "false"
nbDoc.context["theme_option"] = {"light": "Light (default)", "rust": "Rust", "coal": "Coal", "navy": "Navy", "ayu": "Ayu"}.toTable
nbDoc.context["book_title"] = "example mdbook with nimib"
nbDoc.context["git_repository_url"] = "https://github.com/pietroppeter/nimib/tree/main/docs/book"
nbDoc.context["git_repository_icon"] = "fa-github"
when defined(nimibBookEmptyPage):
  nbDoc.context["content"] = "<p>empty test page</p>"
  nbSave