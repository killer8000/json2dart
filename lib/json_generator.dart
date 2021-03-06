import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:json2dart_serialization/generator.dart';
import 'package:json2dart_serialization/storage.dart';

String entityName = null;

bool useJsonKey = true;

bool isCamelCase = true;

var downloadFileName = "";

// const defaultValue = """{
//   "body": "",
//   "data": [1],
//   "input_content":["1"],
//   "list1":[{"name":"hello"}],
//   "number": [1.02],
//   "user":{"name":"abc"}
// }""";
const defaultValue = "";

enum Version { v0, v1 }

Version v = Version.v0;

void main() async {
  isChinese = await _isChinese();
  var dataHelper = CookieHelper();
  TextAreaElement jsonInput = querySelector("#json");
  jsonInput.value = dataHelper.loadJsonString();

  jsonInput.onInput.listen((event) {
    dataHelper.saveJsonString(jsonInput.value);
    refreshData();
  });

  InputElement entityNameEle = querySelector("#out_entity_name");
  entityNameEle.value = dataHelper.loadEntityName();
  entityName = entityNameEle.value;
  entityNameEle.onInput.listen((event) {
    entityName = entityNameEle.value;
    dataHelper.saveEntityName(entityName);
    refreshData();
  });

  ButtonElement formatButton = querySelector("#format");
  formatButton.onClick.listen((click) {
    String pretty;
    pretty = convertJsonString(jsonInput.value);
    try {
      pretty = formatJson(pretty);
    } on Exception {
      return;
    }
    jsonInput.value = pretty;
  });

  InputElement eJsonKey = querySelector("#use_json_key");
  InputElement eCamelCase = querySelector("#camelCase");
  TextAreaElement result = querySelector("#result");
  RadioButtonInputElement v0 = querySelector("#v0");
  RadioButtonInputElement v1 = querySelector("#v1");

  void updateVersioin() {
    if (v1.checked) {
      v = Version.v1;
    } else {
      v = Version.v0;
    }

    dataHelper.saveVersion(v);
  }

  void updateVersionUI() {
    if (v == Version.v1) {
      v1.checked = true;
    } else {
      v1.checked = false;
    }
  }

  v = dataHelper.loadVersion();

  updateVersionUI();

  v0.onInput.listen((event) {
    updateVersioin();
    refreshData();
  });
  v1.onInput.listen((event) {
    updateVersioin();
    refreshData();
  });

  void onJsonKeyChange() {
    useJsonKey = eJsonKey.checked;
    eCamelCase.disabled = !useJsonKey;
    isCamelCase = eCamelCase.checked;
    if (!useJsonKey) isCamelCase = false;
    refreshData();
  }

  eJsonKey.checked = useJsonKey;
  eJsonKey.onInput.listen((event) {
    onJsonKeyChange();
  });

  querySelector("#check_label").onClick.listen((event) {
    eJsonKey.checked = !eJsonKey.checked;
    onJsonKeyChange();
  });

  eCamelCase.checked = isCamelCase;
  eCamelCase.onInput.listen((event) {
    isCamelCase = eCamelCase.checked;
    refreshData();
  });

  querySelector("#camelCaseLabel").onClick.listen((event) {
    eCamelCase.checked = !eCamelCase.checked;
    refreshData();
  });

  refreshData();

  querySelector("#copy").onClick.listen((event) {
    result.focus();
    result.setSelectionRange(0, result.textLength);
    document.execCommand("copy", null, "");
    result.blur();
  });

  ButtonElement saveButton = querySelector("#save");
  saveButton.onClick.listen((event) async {
    Blob blob = Blob([result.value]);
    // FileSystem _filesystem =
    //     await window.requestFileSystem(1024 * 1024, persistent: false);
    // FileEntry fileEntry = await _filesystem.root.createFile('dart_test.csv');
    // FileWriter fw = await fileEntry.createWriter();
    // fw.write(blob);
    // File file = await fileEntry.file();
    AnchorElement saveLink =
        document.createElementNS("http://www.w3.org/1999/xhtml", "a");
    saveLink.href = Url.createObjectUrlFromBlob(blob);
    // saveLink.type = "download";
    saveLink.download = downloadFileName;
    saveLink.click();
  });
}

Future<bool> _isChinese() async {
  // var lang = await findSystemLocale();
  List<MetaElement> elements = querySelectorAll("meta");

  String lang;
  for (var e in elements) {
    var _lang = e.getAttribute("lang");
    if (_lang != null) {
      lang = _lang;
      break;
    }
  }
  if (lang?.contains("zh") == true) {
    return true;
  }

  return false;
}

bool isChinese = false;

void refreshData() async {
  TextAreaElement jsonInput = querySelector("#json");
  var string = jsonInput.value;
  TextAreaElement result = querySelector("#result");

  try {
    formatJson(string);
  } on Exception {
    if (isChinese) {
      result.value = "不是一个正确的json";
    } else {
      result.value = "Not JSON";
    }
    return;
  }
  String entityClassName;
  if (entityName == null || entityName == "" || entityName.trim() == "") {
    entityClassName = "Entity";
  } else {
    entityClassName = entityName;
  }

  var generator = Generator(string, entityClassName, v);
  var dartCode = generator.makeDartCode();
  var dartFileName = ("${generator.fileName}.dart");
  downloadFileName = dartFileName;

  String filePrefix;
  if (isChinese) {
    filePrefix = "应该使用的文件名为:";
  } else {
    filePrefix = "your dart file name is:";
  }
  // print(filePrefix);
  querySelector("#file_name").text = "$filePrefix $dartFileName";

  result.value = dartCode;
}

String formatJson(String jsonString) {
  var map = json.decode(jsonString);
  var prettyString = JsonEncoder.withIndent("  ").convert(map);
  return prettyString;
}
