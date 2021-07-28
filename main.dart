import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    color: Colors.blueAccent,
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();
  List _todoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  Future<Null> _refresh() async {
    await Future.delayed(Duration(
      milliseconds: 1,
    )); // *** retardar a ação pra criar efeito

    setState(() {
      _todoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });
      _saveData();
    });
    return null;
  }

  @override // *** 'ctrl + o' lista os métodos para sobrescrever
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _todoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      // *** n esquecer saporra que att os dados da tela
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _todoList.add(newToDo);
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                  // *** utiizado para dar o tamanho máximo ao TextField
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
                  // ***Fazer atualiação arrasto bottom
                  child: ListView.builder(
                    // *** construir a lista enquanto for rodando
                    padding: EdgeInsets.only(top: 10),
                    // ***passar padding
                    itemCount: _todoList.length,
                    // ***contar a lista pelo tamanho
                    itemBuilder: buildItem,
                  ),
                  onRefresh: _refresh))
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    //*** função anônima passando
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      // *** precisa de key pra saber
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0), // ***alinha botão à esq -1 a 1
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_todoList[index]["title"]), // ***entrada de título
        value: _todoList[index]["ok"], // ***entrada de valores
        secondary: CircleAvatar(
          child: Icon(_todoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _todoList[index]["ok"] = c;
            _saveData();
          });
        }, // *** imagem para o item
      ),
      // *** direção para o arrasto
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          _lastRemovedPos = index;
          _todoList.removeAt(index);

          final snack = SnackBar(
            content: Text("A tarefa \"${_lastRemoved["title"]}\" foi removida"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _todoList.insert(_lastRemovedPos, _lastRemoved);
                  });
                }),
            duration: Duration(seconds: 4),
          );

          Scaffold.of(context)
              .removeCurrentSnackBar(); // ***remover snackbar anterior para n empilhar
          Scaffold.of(context).showSnackBar(snack);

          _saveData();
        });
      }, // ***ações diferentes para cada arrasto
    );
  }

//

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.jason");
  } // ***função para obter arquivo

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  } // ***função para salvar arquivo

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  } // ***função para ler arquivo com tratamento de erro
}
