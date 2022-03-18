import 'dart:convert';
import 'dart:io';
import 'package:pot/pot.dart';

final todoListPot = Pot(() => TodoList());
final todoEditorPot = Pot.replaceable(() => TodoEditor());

void main() {
  todoListPot.create();
  App().menu();
}

class App {
  void menu() {
    stdout.write('1. Show\n2. Add\n9. Exit\n\nSelect a number: ');
    final input = stdin.readLineSync(encoding: utf8) ?? '';
    final number = int.tryParse(input);

    if (number == 1) {
      final list = todoListPot();
      list.show();
    } else if (number == 2) {
      toEditor();
    } else if (number == 9) {
      return;
    } else {
      stdout.writeln('Input a correct number\n');
    }

    menu();
  }

  void toEditor() {
    Pot.pushScope();
    todoEditorPot.replace(() => TodoEditor());

    // The TodoEditor object is created and gets bound to the scope.
    final editor = todoEditorPot();
    editor.enter();

    // The scope is removed, and the object is discarded accordingly.
    Pot.popScope();
  }
}

class TodoList {
  final List<String> data = [];

  void add(String todo) {
    data.add(todo);
  }

  void show() {
    final todos = todoListPot().data;
    if (todos.isEmpty) {
      stdout.writeln('No todo yet.\n');
      return;
    }

    stdout.writeln();
    for (final todo in todos) {
      stdout.writeln('- $todo');
    }
    stdout.writeln();
  }
}

class TodoEditor {
  void enter() {
    stdout.write('Enter a todo: ');
    final input = stdin.readLineSync(encoding: utf8)?.trim() ?? '';

    if (input.isEmpty) {
      stdout.writeln('Todo must not be empty.\n');
      enter();
      return;
    }
    stdout.writeln();

    final list = todoListPot();
    list.add(input);
  }
}
