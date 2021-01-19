import 'dart:io';

import 'package:flutter/material.dart';

class FullImage extends StatefulWidget {
  final File image;

  const FullImage({Key key, this.image}) : super(key: key);

  @override
  _FullImageState createState() => _FullImageState();
}

class _FullImageState extends State<FullImage>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Stack(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: double.infinity,
              child: GestureDetector(
                onTap: () {
                  if (_controller.isCompleted) {
                    _controller.reverse();
                  } else {
                    _controller.forward();
                  }
                },
                // onVerticalDragDown: (details) => Navigator.pop(context),
                child: Image.file(
                  widget.image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Transform.translate(
                  offset: Offset(0, -_controller.value * 84),
                  child: CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back),
                      color: Colors.white,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
