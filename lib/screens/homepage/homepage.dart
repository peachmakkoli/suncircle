import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:custom_horizontal_calendar/custom_horizontal_calendar.dart';
import 'package:custom_horizontal_calendar/date_row.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:suncircle/screens/landingpage/landingpage.dart';
import 'package:suncircle/screens/newtaskform/newtaskform.dart';


class HomePage extends StatefulWidget {
  HomePage({Key key, this.title, this.user}) : super(key: key);

  final String title;
  final FirebaseUser user;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      print(error); // TODO: show dialog with error
    }
  }

  DateTime _selectedDate;
  DateTime _nextDay;

  @override
  void initState() {
    super.initState();
    _resetSelectedDate();
    initializeDateFormatting();
  }

  void _resetSelectedDate() {
    DateTime today = new DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _nextDay = _selectedDate.add(Duration(days: 1));
  }

  List<ChartData> _getChartData(tasks) {
    List<ChartData> _chartData = List<ChartData>();

    // add white space between start of day and start of first task
    _chartData.add(new ChartData(
      '', 
      (tasks[0]['time_start'].seconds - Timestamp.fromDate(_selectedDate).seconds).toDouble(), 
      '', 
      Colors.white
    ));

    for (var i = 0; i < tasks.length; i++) {
      var name = tasks[i]['name'];
      var size = (tasks[i]['time_end'].seconds - tasks[i]['time_start'].seconds).toDouble();
      var duration = size / 3600; // converts to hours

      _chartData.add(new ChartData(name, size, name + '\n($duration hrs)'));
      
      // add white space between tasks
      if (i < tasks.length - 1) {
        _chartData.add(new ChartData(
          '', 
          (tasks[i+1]['time_start'].seconds - tasks[i]['time_end'].seconds).toDouble(), 
          '', 
          Colors.white
        ));
      }
    }

    // add white space between end of last task and end of day
    _chartData.add(new ChartData(
      '', 
      (Timestamp.fromDate(_selectedDate.add(Duration(days: 1))).seconds - tasks[tasks.length - 1]['time_end'].seconds).toDouble(), 
      '', 
      Colors.white
    )); 
    
    return _chartData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        // backgroundColor: Color(0xFFFF737D),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          FlatButton(
            child: Text(
              'Logout',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              signOut().whenComplete(() {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return LandingPage();
                    },
                  ),
                );
              });
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      floatingActionButton: _newTaskButton(),
      body: Center(
        child: Column(
          children: <Widget>[
            CustomHorizontalCalendar(
              onDateChoosen: (date){
                setState(() {
                  _selectedDate = date;
                  _nextDay = date.add(Duration(days: 1));
                });
              },
              inintialDate: _selectedDate,
              height: 60,
              builder: (context, i, d, width) {
                if (i != 2)
                  return DateRow(
                    d,
                    width: width,
                  );
                else
                  return DateRow(
                    d,
                    background: Colors.indigo,
                    selectedDayStyle: TextStyle(color: Colors.white),
                    selectedDayOfWeekStyle: TextStyle(color: Colors.white),
                    selectedMonthStyle: TextStyle(color: Colors.white),width: width,
                  );
              },
            ),
            SizedBox(height: 30),
            StreamBuilder(
              stream: Firestore.instance
                .collection('users')
                .document(widget.user.uid)
                .collection('tasks')
                .where('time_start', isGreaterThanOrEqualTo: _selectedDate)
                .where('time_start', isLessThan: _nextDay)
                .orderBy('time_start')
                .snapshots(),
              builder: (context, snapshot) {
                if(!snapshot.hasData) return Text('Loading data...');
                if(snapshot.data.documents.isEmpty) return Text('No tasks found for selected day.');
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: ExactAssetImage("assets/clock-face.png"), 
                      fit: BoxFit.contain,
                    ),
                  ),
                  height: 420,
                  child: SfCircularChart(series: <CircularSeries>[
                    PieSeries<ChartData, String>(
                      enableSmartLabels: true,
                      dataSource: _getChartData(snapshot.data.documents),
                      pointColorMapper:(ChartData data,  _) => data.color,
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y,
                      radius: '80%',
                      // explode: true,
                      // explodeIndex: 0,
                      dataLabelMapper: (ChartData data, _) => data.text,
                      dataLabelSettings: DataLabelSettings(
                        isVisible: true,
                        useSeriesColor: true,
                      ),
                    )
                  ]),
                ); // Container
              },
            ), // Streambuilder
          ], // <Widget>
        ),
      ), // Center
    ); // Scaffold
  }

  Widget _newTaskButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[ 
        FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return NewTaskForm(title: widget.title);
                },
              ),
            );
          },
          tooltip: 'Add a new task',
          child: Icon(Icons.add, size: 40.0),                  
        ),
      ],
    );
  }
}

class ChartData {
  ChartData(this.x, this.y, this.text, [this.color]);
  final String x;
  final double y;
  final String text;
  final Color color;
}

