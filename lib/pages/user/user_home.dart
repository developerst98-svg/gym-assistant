import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({Key? key}) : super(key: key);

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  Future<void> _loadPageData() async {
    // Simulate loading time - you can replace this with actual data loading
    await Future.delayed(const Duration(seconds: 0));
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Home'),
      ),
      body: _isLoading
          ? Center(
              child: LoadingAnimationWidget.dotsTriangle(
                color: Theme.of(context).colorScheme.secondary,
                size: 64,
              ),
            )
          : const Center(
              child: Text(
                'Welcome to your fitness journey!',
                style: TextStyle(fontSize: 18),
              ),
            ),
    );
  }
}
