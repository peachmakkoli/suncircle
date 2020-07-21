import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:card_settings/card_settings.dart';

import 'package:suncircle/components/loading_dialog.dart';
import 'package:suncircle/components/submit_form_button.dart';
import 'package:suncircle/models/category_model.dart';
import 'package:suncircle/services/category/save_category.dart';

final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

class CategoryForm extends StatefulWidget {
  CategoryForm({Key key, this.title, this.subtitle, this.user, this.category})
      : super(key: key);

  final String title;
  final String subtitle;
  final FirebaseUser user;
  final CategoryModel category;

  @override
  CategoryFormState createState() => CategoryFormState();
}

class CategoryFormState extends State<CategoryForm> {
  CategoryModel _category;
  String _originalCategoryName;

  DateTime selectedDate;
  DateTime nextDay;

  bool _autoValidate = false;
  bool _unique = true;

  @override
  void initState() {
    super.initState();
    initModel();
  }

  void initModel() {
    _category = widget.category;
    _originalCategoryName = widget.category.name;
  }

  Future submitForm() async {
    final form = _formKey.currentState;

    LoadingDialog.show(context);

    if (form.validate()) {
      saveCategory(_category, widget.user).whenComplete(() {
        LoadingDialog.hide(context);
        Navigator.of(context).pop();
      });
    } else {
      LoadingDialog.hide(context);
      setState(() => _autoValidate = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title}: ${widget.subtitle}'),
        // backgroundColor: Color(0xFFFF737D),
      ),
      backgroundColor: Colors.white,
      floatingActionButton: submitFormButton(context, submitForm),
      body: FutureBuilder<String>(
          future: checkUnique(_category.name, _originalCategoryName,
              widget.user, widget.subtitle),
          builder: (context, snapshot) {
            return Stack(
              children: <Widget>[
                Form(
                  key: _formKey,
                  child: CardSettings(
                    showMaterialonIOS: false,
                    labelWidth: 150,
                    contentAlign: TextAlign.right,
                    children: <CardSettingsSection>[
                      CardSettingsSection(
                        header: CardSettingsHeader(
                          label: 'Category',
                        ),
                        children: <CardSettingsWidget>[
                          CardSettingsText(
                            label: 'Name',
                            initialValue: _category.name,
                            requiredIndicator:
                                Text('*', style: TextStyle(color: Colors.red)),
                            validator: (value) {
                              if (value.isEmpty) return 'Name is required.';
                              if (value == snapshot.data)
                                return 'Category already exists.';
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _category.name = value;
                              });
                            },
                          ),
                          CardSettingsColorPicker(
                            label: 'Color',
                            initialValue:
                                intelligentCast<Color>(_category.color),
                            autovalidate: _autoValidate,
                            pickerType: CardSettingsColorPickerType.block,
                            onChanged: (value) {
                              setState(() {
                                _category.color = colorToString(value);
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
    );
  }
}
