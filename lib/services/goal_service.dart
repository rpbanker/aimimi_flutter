import 'package:aimimi/models/goal.dart';
import 'package:aimimi/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalService {
  final String uid;
  GoalService({this.uid});

  final CollectionReference<Map<String, dynamic>> goalCollection =
      FirebaseFirestore.instance.collection("goals");

  final CollectionReference<Map<String, dynamic>> userCollection =
      FirebaseFirestore.instance.collection("users");

  Stream<List<Goal>> get goals {
    return goalCollection.snapshots().map(
        (QuerySnapshot<Map<String, dynamic>> querySnapshot) =>
            querySnapshot.docs
                .map((DocumentSnapshot<Map<String, dynamic>> goal) => (Goal(
                      title: goal.data()["title"],
                      category: goal.data()["category"],
                      period: goal.data()["period"],
                      frequency: goal.data()["frequency"],
                      timespan: goal.data()["timespan"],
                      publicity: goal.data()["publicity"],
                      description: goal.data()["description"],
                    )))
                .toList());
  }

  List<UserGoal> _createUserGoals(
      QuerySnapshot<Map<String, dynamic>> querySnapshot) {
    return querySnapshot.docs
        .map<UserGoal>(
            (DocumentSnapshot<Map<String, dynamic>> userGoal) => (UserGoal(
                  accuracy: userGoal.data()["accuracy"].toDouble(),
                  checkIn: userGoal.data()["checkIn"],
                  checkInSuccess: userGoal.data()["checkInSuccess"],
                  checkedIn: userGoal.data()["checkedIn"],
                  dayPassed: userGoal.data()[""],
                  goalID: userGoal.id,
                  goal: Goal(
                    title: userGoal.data()["goal"]["title"],
                    category: userGoal.data()["goal"]["category"],
                    period: userGoal.data()["goal"]["period"],
                    frequency: userGoal.data()["goal"]["frequency"],
                    timespan: userGoal.data()["goal"]["timespan"],
                    publicity: userGoal.data()["goal"]["publicity"],
                    description: userGoal.data()["goal"]["description"],
                  ),
                )))
        .toList();
  }

  Stream<List<UserGoal>> get userGoals {
    return userCollection
        .doc(uid)
        .collection("goals")
        .snapshots()
        .map(_createUserGoals);
  }

  void addGoal(title, category, description, publicity, period, frequency,
      timespan) async {
    DocumentReference doc = await goalCollection.add({
      'title': title,
      'category': category,
      'description': description,
      'publicity': publicity,
      'period': period,
      'frequency': frequency,
      'timespan': timespan,
      'createBy': {
        'uid': FirebaseAuth.instance.currentUser.uid,
        'username': FirebaseAuth.instance.currentUser.displayName,
      }
    });
    print(doc.id);
    await userCollection
        .doc(FirebaseAuth.instance.currentUser.uid)
        .collection("goals")
        .doc(doc.id.toString())
        .set({
      "accuracy": 0,
      "checkIn": 0,
      "checkInSuccess": 0,
      "goal": {
        'description': description,
        'frequency': frequency,
        'period': period,
        'publicity': publicity,
        'timespan': timespan,
        'title': title,
      },
    });
  }

  Future checkInGoal(int checkIn, UserGoal selectedGoal) {
    final bool doEnoughTimes = checkIn >= selectedGoal.goal.frequency;

    if (doEnoughTimes) {
      return userCollection
          .doc(FirebaseAuth.instance.currentUser.uid)
          .collection("goals")
          .doc(selectedGoal.goalID)
          .update({
        "checkIn": checkIn,
        "checkInSuccess": FieldValue.increment(1),
        "checkedIn": true,
        "dayPassed": FieldValue.increment(1)
      });
    }

    return userCollection
        .doc(FirebaseAuth.instance.currentUser.uid)
        .collection("goals")
        .doc(selectedGoal.goalID)
        .update({"checkIn": checkIn});
  }
}
