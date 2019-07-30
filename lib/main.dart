import 'package:flutter/material.dart';
import 'package:flutter_moor_demo/store/main/main.store.dart';

import 'db/moor.db.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime newTaskDate;
  TextEditingController controller;
  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: mainStore.dbService.tasks$,
              initialData: List<Task>(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.active) {
                  List<Task> tasks = snap.data;
                  if (tasks.isEmpty) return Center(child: Text('Not Data'));
                  return ListView.builder(
                    itemCount: tasks.length + 1,
                    itemBuilder: (context, int index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(child: Text('taskS #${tasks.length}')),
                        );
                      }
                      final task = tasks[index - 1];
                      return Dismissible(
                        key: ValueKey(task.id),
                        background: Container(color: Colors.red),
                        onDismissed: (DismissDirection d) {
                          mainStore.dbService.database.deleteTask(task);
                        },
                        child: CheckboxListTile(
                          title: Text(task.name),
                          subtitle: Text(task.dueData?.toString() ?? 'No date'),
                          value: task.completed,
                          onChanged: (bool nv) {
                            mainStore.dbService.database
                                .updateTask(task.copyWith(completed: nv));
                          },
                        ),
                      );
                    },
                  );
                } else if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else {
                  return SizedBox();
                }
              },
            ),
          ),
          ListTile(
            title: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'Task Name'),
              onSubmitted: (String v) {
                mainStore.dbService.database.insertTask(
                  name: v.trim(),
                  dueData: newTaskDate,
                );

                _reset();
              },
            ),
            trailing: IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () async {
                DateTime now = DateTime.now();
                Duration d = Duration(days: 10);
                newTaskDate = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now.subtract(d),
                    lastDate: now.add(d));
              },
            ),
          )
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      controller.clear();
      newTaskDate = null;
    });
  }
}
