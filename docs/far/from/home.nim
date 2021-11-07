import nimib, strutils
nbInit
nb.context["home_path"] = nb.context["home_path"].castStr.replace("/", r"\") # for CI since I run locally on Windows and CI runs on Linux: behaviour is the same
nb.context["here_path"] = nb.context["here_path"].castStr.replace("/", r"\") # for CI since I run locally on Windows and CI runs on Linux: behaviour is the same
nb.partials["document"] = """
<a href=".">🕷️</a> is {{here_path}} <a href="{{home_path}}">🏡</a> ({{home_path}})
"""
nbSave