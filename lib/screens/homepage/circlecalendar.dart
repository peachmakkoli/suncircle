import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';


Widget circleCalendar(user, _selectedDate, _nextDay) {
  return StreamBuilder(
    stream: Firestore.instance
      .collection('users')
      .document(user.uid)
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
            dataSource: _getChartData(snapshot.data.documents, _selectedDate, _nextDay),
            pointColorMapper:(ChartData data,  _) => data.color,
            xValueMapper: (ChartData data, _) => data.id,
            yValueMapper: (ChartData data, _) => data.duration,
            radius: '80%',
            // explode: true,
            // explodeIndex: 0,
            dataLabelMapper: (ChartData data, _) => data.name,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              useSeriesColor: true,
            ),
          )
        ]),
      ); 
    },
  ); 
}

List<ChartData> _getChartData(tasks, _selectedDate, _nextDay) {
    List<ChartData> _chartData = List<ChartData>();
    double _getDuration(Timestamp timeEnd, Timestamp timeStart) {
      return (timeEnd.seconds - timeStart.seconds) / 3600;
    }

    // add white space between start of day and start of first task
    _chartData.add(ChartData(
      '',
      '',
      DateTime.now(),
      DateTime.now(),
      '',
      _getDuration(tasks[0]['time_start'], Timestamp.fromDate(_selectedDate)), 
      Colors.white,
    ));

    for (var i = 0; i < tasks.length; i++) {
      _chartData.add(ChartData(
        tasks[i].documentID, 
        tasks[i]['name'],
        tasks[i]['time_start'].toDate(),
        tasks[i]['time_end'].toDate(),
        tasks[i]['notes'],
        _getDuration(tasks[i]['time_end'], tasks[i]['time_start']), 
      ));
      
      // add white space between tasks
      if (i < tasks.length - 1) {
        _chartData.add(ChartData(
          '',
          '',
          DateTime.now(),
          DateTime.now(),
          '',
          _getDuration(tasks[i+1]['time_start'], tasks[i]['time_end']), 
          Colors.white
        ));
      }
    }

    // add white space between end of last task and end of day
    _chartData.add(ChartData(
      '',
      '',
      DateTime.now(),
      DateTime.now(),
      '', 
      _getDuration(Timestamp.fromDate(_selectedDate.add(Duration(days: 1))), tasks[tasks.length - 1]['time_end']), 
      Colors.white
    )); 
    
    return _chartData;
  }

class ChartData {
  ChartData(this.id, this.name, this.timeStart, this.timeEnd, this.notes, this.duration, [this.color]);
  final String id;
  final String name;
  final DateTime timeStart;
  final DateTime timeEnd;
  final double duration;
  final String notes;
  final Color color;
}