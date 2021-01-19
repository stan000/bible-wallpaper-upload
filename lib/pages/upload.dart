import 'dart:io';

import 'package:bible_wallpaper_upload/pages/fullScreenImage.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as Img;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

final storageRef = FirebaseStorage.instance.ref();
final booksRef = FirebaseFirestore.instance.collection('books');
final categoriesRef = FirebaseFirestore.instance.collection('categories');
final allWallpapersRef = FirebaseFirestore.instance.collection('all');
final dailyWallpaperRef =
    FirebaseFirestore.instance.collection('daily_wallpapers_queue');
final isFeaturedWallpaperRef =
    FirebaseFirestore.instance.collection('featured');
final timeStamp = DateTime.now();

class Upload extends StatefulWidget {
  @override
  _UploadState createState() => _UploadState();
}

enum AppState {
  free,
  picked,
  cropped,
}

class _UploadState extends State<Upload> {
  TextEditingController chapterController = TextEditingController();
  TextEditingController verseController = TextEditingController();
  TextEditingController bookController = TextEditingController();
  // TextEditingController isDailyVerseController = TextEditingController();
  TextEditingController categoriesController = TextEditingController();
  // List<bool> _selected = List();
  final _formKey = GlobalKey<FormState>();
  String imageErrorMessage;
  String wallpaperId = Uuid().v4();
  List<String> categories = List<String>();
  bool isDailyVerse = false;
  bool isFeatured = false;
  bool isUploading = false;
  File image;
  AppState state;
  List oldTestament = [
    'genesis',
    'exodus',
    'leviticus',
    'numbers',
    'deuteronomy',
    'joshua',
    'judges',
    'ruth',
    '1 samuel',
    '2 samuel',
    '1 kings',
    '2 kings',
    '1 chronicles',
    '2 chronicles',
    'ezra',
    'nehemiah',
    'esther',
    'job',
    'psalm',
    'proverbs',
    'ecclesiastes',
    'song of solomon',
    'isaiah',
    'jeremiah',
    'lamentations',
    'ezekiel',
    'daniel',
    'hosea',
    'joel',
    'amos',
    'obadiah',
    'jonah',
    'micah',
    'nahum',
    'habakkuk',
    'zephaniah',
    'haggai',
    'zechariah',
    'malachi'
  ];
  List newTestament = [
    'matthew',
    'mark',
    'luke',
    'john',
    'acts',
    'romans',
    '1 corinthians',
    '2 corinthians',
    'galatians',
    'ephesians',
    'philippians',
    'colossians',
    '1 thessalonians',
    '2 thessalonians',
    '1 timothy',
    '2 timothy',
    'titus',
    'philemon',
    'hebrews',
    'james',
    '1 peter',
    '2 peter',
    '1 john',
    '2 john',
    '3 john',
    'jude',
    'revelation'
  ];

  @override
  void initState() {
    super.initState();
    state = AppState.free;
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });

    var imagesDownloadUrl = await saveImageToCloudStorage(
      book: bookController.text,
      chapter: int.parse(chapterController.text),
      verse: int.parse(verseController.text),
    );

    await createWallpaperInFirestore(
      // imagesDownloadUrl[0] = wallpaper,
      // imagesDownloadUrl[1] = thumbnail
      wallpaperDownloadUrl: imagesDownloadUrl[0],
      thumbnailDownloadUrl: imagesDownloadUrl[1],
      book: bookController.text,
      chapter: int.parse(chapterController.text),
      verse: int.parse(verseController.text),
    );

    reset();

    setState(() {
      isUploading = false;
      wallpaperId = Uuid().v4();
    });
    return SnackBar(content: Text('Wallpaper added'));
  }

  handleValidation() {
    if (image == null) {
      setState(() {
        imageErrorMessage = 'No Image you idiot';
      });
    }
    if (_formKey.currentState.validate() && image != null) {
      updateCategories();
      handleSubmit();
    }
  }

  reset() {
    bookController.text = '';
    chapterController.text = '';
    verseController.text = '';
    setState(() {
      categories = [];
      image = null;
      imageErrorMessage = null;
      // _selected = null;
    });
  }

  saveImageToCloudStorage({String book, int chapter, int verse}) async {
    // Upload full Image
    TaskSnapshot uploadTask1 = await storageRef
        .child('wallpapers')
        .child('$book-$chapter-$verse--$wallpaperId.jpg')
        .putFile(image);
    // TaskSnapshot storageSnap1 = await uploadTask1.onComplete;
    String wpUrl = await uploadTask1.ref.getDownloadURL();

    // Make and Upload thumbnail
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Img.Image imageTemp = Img.decodeImage(image.readAsBytesSync());
    Img.Image resizedImg = Img.copyResize(imageTemp, height: 500);
    var thumbnail = new File('$path/thumb.jpg')
      ..writeAsBytesSync(Img.encodeJpg(resizedImg));

    TaskSnapshot uploadTask2 = await storageRef
        .child('thumbnails')
        .child('thumb-$book-$chapter-$verse--$wallpaperId.jpg')
        .putFile(thumbnail);
    String thUrl = await uploadTask2.ref.getDownloadURL();
    return [wpUrl, thUrl];
  }

  createWallpaperInFirestore({
    @required String book,
    @required int chapter,
    @required int verse,
    @required String wallpaperDownloadUrl,
    @required String thumbnailDownloadUrl,
  }) async {
    var categoriesLower =
        categories.map((category) => category.toLowerCase()).toSet().toList();

    var wallpaperData = {
      'wallpaperId': wallpaperId,
      'book': book.toLowerCase(),
      'chapter': chapter,
      'verse': verse,
      'categories': categoriesLower,
      'timestamp': DateTime.now(),
      'downloads': 0,
      'likes': 0,
      'isDailyVerse': isDailyVerse,
      'isFeatured': isFeatured,
      'wallpaperDownloadUrl': wallpaperDownloadUrl,
      'thumbnailDownloadUrl': thumbnailDownloadUrl,
    };

    // add to collection of all wallpapers
    await allWallpapersRef.doc(wallpaperId).set(wallpaperData);

    // Add to books database
    await booksRef
        .doc(book)
        .collection(book)
        .doc(wallpaperId)
        .set(wallpaperData);

    // add books to categories database
    categories.forEach((category) async {
      await categoriesRef
          .doc(category)
          .collection(category)
          .doc(wallpaperId)
          .set(wallpaperData);
    });

    // add to daily verses database
    if (isDailyVerse) {
      await dailyWallpaperRef.doc(wallpaperId).set(wallpaperData);
    }

    // add featured to database
    if (isFeatured) {
      await isFeaturedWallpaperRef.doc(wallpaperId).set(wallpaperData);
    }
  }

  viewImage() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullImage(image: image),
        ));
  }

  TextFormField customForm(String text, TextEditingController controller) {
    return TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(hintText: text, labelText: text),
        validator: (value) {
          if (value.isEmpty) {
            return 'What $text?';
          }
          return null;
        });
  }

  handlePickImage() async {
    PickedFile file = await ImagePicker().getImage(source: ImageSource.gallery);
    setState(() {
      image = File(file.path);
    });
  }

  updateCategories() {
    if (categoriesController.text.trimRight().isNotEmpty) {
      categories
          .add(categoriesController.text.toLowerCase().trimRight().trimLeft());
      // _selected.add(true);
      categoriesController.clear();
    }

    setState(() {
      categories = categories;
      // _selected = _selected;
    });
  }

  Widget buildChips() {
    List<Widget> chips = new List();
    for (int i = 0; i < categories.length; i++) {
      InputChip actionChip = InputChip(
        label: Text(categories[i]),
        onPressed: () {
          setState(() {
            // _selected[i] = !_selected[i];
          });
        },
        onDeleted: () {
          categories.removeAt(i);
          // _selected.removeAt(i);

          setState(() {
            categories = categories;
            // _selected = _selected;
          });
        },
      );
      chips.add(actionChip);
    }

    return ListView(
      scrollDirection: Axis.horizontal,
      children: chips,
    );
  }

  Widget linearProgress(context) {
    return isUploading
        ? PreferredSize(
            preferredSize: Size(double.infinity, 4.0),
            child: LinearProgressIndicator(
              backgroundColor: Colors.blue,
              valueColor: AlwaysStoppedAnimation(Colors.blue[900]),
            ),
          )
        : PreferredSize(child: SizedBox.shrink(), preferredSize: Size.zero);
  }

  // Future<Null> cropImage() async {
  //   File croppedFile = await ImageCropper.cropImage(
  //     sourcePath: image.path,
  // aspectRatioPresets: Platform.isAndroid
  //     ? [
  //         CropAspectRatioPreset.square,
  //         CropAspectRatioPreset.ratio3x2,
  //         CropAspectRatioPreset.original,
  //         CropAspectRatioPreset.ratio4x3,
  //         CropAspectRatioPreset.ratio16x9
  //       ]
  //     : [
  //         CropAspectRatioPreset.original,
  //         CropAspectRatioPreset.square,
  //         CropAspectRatioPreset.ratio3x2,
  //         CropAspectRatioPreset.ratio4x3,
  //         CropAspectRatioPreset.ratio5x3,
  //         CropAspectRatioPreset.ratio5x4,
  //         CropAspectRatioPreset.ratio7x5,
  //         CropAspectRatioPreset.ratio16x9
  //       ],
  // androidUiSettings: AndroidUiSettings(
  //     toolbarTitle: 'Cropper',
  //     toolbarColor: Colors.deepOrange,
  //     toolbarWidgetColor: Colors.white,
  //     initAspectRatio: CropAspectRatioPreset.original,
  //     lockAspectRatio: false),
  // iosUiSettings: IOSUiSettings(
  //   title: 'Cropper',
  // ),
  //   );
  //   if (croppedFile != null) {
  //     image = croppedFile;
  //     setState(() {
  //       state = AppState.cropped;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.cancel),
          onPressed: reset,
        ),
        title: Text('Upload Wallpaper'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add_box),
            onPressed: handleValidation,
          ),
        ],
        bottom: linearProgress(context),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 14),
        children: <Widget>[
          image == null
              ? Center(child: Text('No image'))
              : Container(
                  child: GestureDetector(
                    child: Image.file(
                      image,
                      height: 300.0,
                    ),
                    onTap: viewImage,
                    // onDoubleTap: cropImage,
                  ),
                ),
          imageErrorMessage != null && image == null
              ? Center(
                  child: Text(
                    imageErrorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                )
              : SizedBox.shrink(),
          MaterialButton(
            color: Colors.blue,
            child: Text('Add image'),
            onPressed: handlePickImage,
          ),
          Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: bookController,
                  decoration: InputDecoration(
                    hintText: 'Book',
                    labelText: 'Book',
                  ),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'What book?';
                    }
                    if (!oldTestament.contains(
                            value.toLowerCase().trimRight().trimLeft()) &&
                        !newTestament.contains(
                            value.toLowerCase().trimRight().trimLeft())) {
                      return 'Wrong spelling you idiot';
                    }
                    return null;
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    DropdownButton(
                      hint: Text('Old Testament'),
                      items: oldTestament.map((value) {
                        return new DropdownMenuItem<String>(
                          value: value,
                          child: new Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        bookController.text = value;
                      },
                    ),
                    DropdownButton(
                      hint: Text('New Testament'),
                      items: newTestament.map((value) {
                        return new DropdownMenuItem<String>(
                          value: value,
                          child: new Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        bookController.text = value;
                      },
                    ),
                  ],
                ),
                customForm('chapter', chapterController),
                customForm('verse', verseController),
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text('Will it be a daily verse?'),
                ),
                // Mark as daily wallpaper
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    FlatButton.icon(
                      label: const Text('Yes'),
                      icon: Radio(
                        value: true,
                        groupValue: isDailyVerse,
                        onChanged: (value) {
                          setState(() {
                            isDailyVerse = value;
                          });
                        },
                      ),
                      onPressed: () {
                        setState(() {
                          isDailyVerse = true;
                        });
                      },
                    ),
                    FlatButton.icon(
                      label: const Text('No'),
                      icon: Radio(
                        value: false,
                        groupValue: isDailyVerse,
                        onChanged: (value) {
                          setState(() {
                            isDailyVerse = value;
                          });
                        },
                      ),
                      onPressed: () {
                        setState(() {
                          isDailyVerse = false;
                        });
                      },
                    ),
                  ],
                ),
                // mark as Featured
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text('Will it be a featured verse?'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    FlatButton.icon(
                      label: const Text('Yes'),
                      icon: Radio(
                        value: true,
                        groupValue: isFeatured,
                        onChanged: (value) {
                          setState(() {
                            isFeatured = value;
                          });
                        },
                      ),
                      onPressed: () {
                        setState(() {
                          isFeatured = true;
                        });
                      },
                    ),
                    FlatButton.icon(
                      label: const Text('No'),
                      icon: Radio(
                        value: false,
                        groupValue: isFeatured,
                        onChanged: (value) {
                          setState(() {
                            isFeatured = value;
                          });
                        },
                      ),
                      onPressed: () {
                        setState(() {
                          isFeatured = false;
                        });
                      },
                    ),
                  ],
                ),

                // Show Categories
                Container(
                  height: 30,
                  child:
                      categories.length != 0 ? buildChips() : SizedBox.shrink(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: TextFormField(
                        controller: categoriesController,
                        decoration: InputDecoration(
                          labelText: "Select Categories",
                        ),
                        onEditingComplete: updateCategories,
                      ),
                    ),
                    RaisedButton(
                      child: Text('add'),
                      onPressed: updateCategories,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 14.0),
                  child: MaterialButton(
                    child: Text('Upload'),
                    color: Colors.blue,
                    onPressed: handleValidation,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
