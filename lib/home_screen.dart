import 'package:flutter/material.dart';
import 'package:todo_app/db_helper.dart';

class HomeScreen extends StatefulWidget{
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _allData = [];
  List<bool> _checkboxList = [];
  bool _isLoading = true;
  bool _checkbox = false;

  void _refreshData() async {
    final data = await SQLHelper.getAllData();
    setState(() {
      _allData = data;
      _checkboxList = List.generate(data.length, (index) => data[index]['isChecked'] == 1);
      _isLoading = false;
    });
  }

  @override
  void initState(){
    super.initState();
    _refreshData();
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  void showBottomSheet(int? id)
  async{
    if(id!=null){
      final existingData = _allData.firstWhere((element) => element['id'] == id);
      _titleController.text = existingData['title'];
      _descController.text = existingData['desc'];
      setState(() {
        _checkbox = existingData['isChecked'] == 1;
      });
    } else {
      setState(() {
        _checkbox = false;
      });
    }

    showModalBottomSheet(
      elevation: 5,
      isScrollControlled: true,
      context: context,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          top: 30,
          left: 15,
          right: 15,
          bottom: MediaQuery.of(context).viewInsets.bottom + 50,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Title"
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Description"
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () async{
                  if(id == null){
                    await _addData();
                  }
                  if(id != null){
                    await _updateData(id, _checkbox);
                  }

                  _titleController.text = "";
                  _descController.text = "";
                  Navigator.of(context).pop();
                  print("Task added");
                },
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(id == null ? "Add Task" : "Update Task",
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addData()
  async{
    await SQLHelper.createData(_titleController.text, _descController.text, _checkbox);
    _checkboxList.add(_checkbox);
    _refreshData();
  }

  Future<void> _updateData(int id, bool checkbox)
  async{
    await SQLHelper.updateData(id, _titleController.text, _descController.text, checkbox);
    final index = _allData.indexWhere((element) => element['id'] == id);
    if (index != -1) {
      setState(() {
        _allData[index]['isChecked'] = checkbox ? 1 : 0;
        _checkboxList[index] = checkbox;
      });
    }
    _refreshData();
  }

  void _deleteData(int id) async{
    await SQLHelper.deleteData(id);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(
        backgroundColor: Colors.red,
        content: Text("Task Deleted")));
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("To Do Application"),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        itemCount: _allData.length,
        itemBuilder: (context, index) => Card(
          margin: EdgeInsets.all(15),
          child: CheckboxListTile(
            title: Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Text(
                _allData[index]['title'],
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
            subtitle: Text(
              _allData[index]['desc'],
            ),
            value: _checkboxList[index],
            onChanged: (newValue) {
              setState(() {
                _checkboxList[index] = newValue!;
              });
              _updateData(
                _allData[index]['id'],
                newValue!,
              );
            },
            controlAffinity: ListTileControlAffinity.leading,
            secondary: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    showBottomSheet(_allData[index]['id']);
                  },
                  icon: Icon(
                    Icons.edit,
                    color: Colors.black54,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _deleteData(_allData[index]['id']);
                  },
                  icon: Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showBottomSheet(null),
        child: Icon(Icons.add_circle_sharp),
      ),
    );
  }
}