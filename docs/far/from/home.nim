import nimib, strutils
nbInit
nbDoc.context["home_path"] = nbDoc.context["home_path"].castStr.replace("/", r"\") # for CI since I run locally on Windows and CI runs on Linux: behaviour is the same
nbDoc.partials["document"] = """
<a href=".">🕷️</a> is {{here_path}} <a href="{{home_path}}">🏡</a> ({{home_path}})
"""
nbSave