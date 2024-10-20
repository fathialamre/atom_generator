# Atom Generator

Atom Generator is a package to generate GetX routes, bindings, forms and more, that generator using [source_gen](https://github.com/dart-lang/source_gen).

**Usage**

Generator
Add the generator to your dev dependencies


    dependencies: 
     atom_annotations: ^0.0.1

**Define and Generate your Code**

    import 'package:atom_annotations/atom_annotations.dart';  
	import 'package:flutter/material.dart';
	
    @PageRouter('/posts')  
	class PostsPage extends StatelessWidget {  
	  const PostsPage({super.key});  
	  
	  @override  
	  Widget build(BuildContext context) {  
	  return const Placeholder();  
	  }  
	}

Any page that needs to be added to the `GetPages` list should be annotated with `@PageRouter('route-name')`, replacing `route-name` with the route of that page.

then run the generator

    pub run build_runner build


A new dart file will be created in the root of the project called `app_routes.dart`. This file will contain the page routes, and the file output will be as follows:


	class AppRoutes {  
	  static List<GetPage> routes() {  
	  return [PostsPageRoute.route()];  
	  }  
	}  
	  
	class PostsPageRoute {  
	  static GetPage route() {  
	  return GetPage(  
	  name: '/posts',  
	      page: () => PostsPage(),  
	      binding: BindingsBuilder(() {}),  
	    );  
	  }  
	  
	  void open() {  
	  Get.toNamed('/posts', arguments: {});  
	  }  
	}

An `AppRoutes` class will be created, containing a static method called `routes` that returns a list of `GetPage`. For each page, a specific class will be generated, consisting of the page's name with `Route` added at the end.

This class will include a `route` method that returns a `GetPage` with the page path, page, and bindings. Additionally, an `open` method will be added to allow access to the page later.# atom_generator
