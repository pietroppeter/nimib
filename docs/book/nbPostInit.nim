when not defined(nimibCustomPostInit):
  import nimib
  nbInit
nbDoc.context["language"] = "en-us"
nbDoc.context["default_theme"] = "light"
nbDoc.context["description"] = "example mdbook with nimib"
nbDoc.context["path_to_root"] = nbDoc.context["home_path"].castStr & "/" # I probably should make sure to have / at the end
nbDoc.context["preferred_dark_theme"] = "false"
nbDoc.context["theme_option"] = {"light": "", "rust": "", "coal": "", "navy": "", "ayu": ""}.toTable
nbDoc.context["book_title"] = "example mdbook with nimib"
nbDoc.context["git_repository_url"] = ""
nbDoc.context["git_repository_icon"] = ""
when not defined(nimibCustomPostInit):
  nbDoc.context["content"] = "<p>empty test page</p>"
  nbSave