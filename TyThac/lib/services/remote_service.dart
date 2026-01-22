import 'dart:convert';
import 'package:http/http.dart' as http;

class RemoteService {
  Future<String> login(String address, String userid, String password, String firebaseToken, String version) async {
    try {
      final response = await http.post(
        Uri.parse('$address/api/ERP/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'UserID': userid,
          'Password': password,
          'firebaseToken': firebaseToken,
          'version': version
        })
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return response.body;
      }
      else {
        throw Exception('Http failed');
      }
    } catch (ex) {
      return ex.toString();
    }
  }

  Future<String> updateUserPassword(String address, String userid, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$address/api/ERP/updateUserPassword'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'UserID': userid,
          'Password': password
        })
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return response.body;
      }
      else {
        throw Exception('Http failed');
      }
    } catch (ex) {
      return ex.toString();
    }
  }

  Future<String> getAppLatestVersion() async {
    try {
      bool github = true;
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/danny0614/Tythac/releases/latest')
      ).timeout(const Duration(seconds: 5), onTimeout: () async {
        try {
          github = false;
          final response2 = await http.get(
            Uri.parse('https://192.168.23.202/api/v4/projects/58/releases/permalink/latest')
          ).timeout(const Duration(seconds: 5));

          if (response2.statusCode == 200) {
            return http.Response('{"From": "GitLab", "Body": ${response2.body}}', 200);
          }
          else {
            throw Exception('Http failed');
          }
        } catch (ex) {
          return http.Response('Http failed', 500);
        }
      });

      if (response.statusCode == 200) {
        if (github) {
          return '{"From": "GitHub", "Body": ${response.body}}';
        }
        else {
          return response.body;
        }
      }
      else {
        throw Exception('Http failed');
      }
    } catch (ex) {
      return ex.toString();
    }
  }

  Future<String> getScheduleData(String address, String month, String building) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getScheduleData'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Month': month,
        'Building': building
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getMonthOrder(String address, String lean, String month, String type, String order) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getMonthOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Lean': lean,
        'PlanMonth': month,
        'Type': type,
        'Order': order
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getMonthProcessingOrder(String address, String lean, String month, String type, String order) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getMonthProcessingOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Lean': lean,
        'PlanMonth': month,
        'Type': type,
        'Order': order
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getDispatchedOrder(String address, String lean, String order) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getDispatchedOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Lean': lean,
        'Order': order
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getProcessingDispatchedOrder(String address, String lean, String order) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getProcessingDispatchedOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Lean': lean,
        'Order': order
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getBuildingMonthlyCapacity(String address, String date) async {
    try {
      final response = await http.post(
        Uri.parse('$address/api/ERP/getBuildingMonthlyCapacity'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'Date': date
        })
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return response.body;
      }
      else {
        throw Exception('Http failed');
      }
    } catch (ex) {
      return ex.toString();
    }
  }

  Future<String> getLeanMonthlyCapacity(String address, String building, String lean, String type, String date) async {
    try {
      final response = await http.post(
        Uri.parse('$address/api/ERP/getLeanMonthlyCapacity'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'Building': building,
          'Lean': lean,
          'Type': type,
          'Date': date
        })
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return response.body;
      }
      else {
        throw Exception('Http failed');
      }
    } catch (ex) {
      return ex.toString();
    }
  }

  Future<String> getCuttingDispatchedOrderProgress(String address, String lean) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getCuttingDispatchedOrderProgress'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Lean': lean,
      })
    ).timeout(const Duration(seconds: 120));
    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getProcessingDispatchedOrderProgress(String address, String lean) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getProcessingDispatchedOrderProgress'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Lean': lean,
      })
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getStitchingDispatchedOrderProgress(String address, String lean) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getStitchingDispatchedOrderProgress'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Lean': lean
      })
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getAssemblyDispatchedOrderProgress(String address, String lean) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getAssemblyDispatchedOrderProgress'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Lean': lean
      })
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getFactoryLean(String address, String month, String type) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getFactoryLean'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'PlanMonth': month,
        'Type': type
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getOrderPart(String address, String order) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getOrderPart'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getProcessingDispatchFlow(String address, String order) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getProcessingDispatchFlow'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getProcessingReportingFlow(String address, String order) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getProcessingReportingFlow'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getOrderDispatchedPart(String address, String order) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getOrderDispatchedPart'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getOrderSize(String address, String order, String partID) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getOrderSize'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'PartID': partID
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getOrderProcessingSize(String address, String order, String section) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getOrderProcessingSize'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'Section': section
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getOrderCycle(String address, String order, String partID) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getOrderCycle'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'PartID': partID
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getOrderProcessingCycle(String address, String order, String section) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getOrderProcessingCycle'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'Section': section
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getOrderSizeRun(String address, String order, String partID) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getOrderSizeRun'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'PartID': partID
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getOrderProcessingSizeRun(String address, String order, String section) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getOrderProcessingSizeRun'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'Section': section
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getOrderDispatchedSizeRun(String address, String order, String partID) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getOrderDispatchedSizeRun'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'PartID': partID
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getOrderProcessingDispatchedSizeRun(String address, String order, String section) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getOrderProcessingDispatchedSizeRun'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'Section': section
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> generateCuttingWorkOrder(String address, String order, String userID, String department, String factory, String partID, dynamic selection, String type) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/generateCuttingWorkOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'UserID': userID,
        'Factory': factory,
        'Department': department,
        'Type': type,
        'PartID': partID,
        'Cycle': selection
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> generateProcessingWorkOrder(String address, String order, String userID, String department, String factory, String section, dynamic selection) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/generateProcessingWorkOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'UserID': userID,
        'Factory': factory,
        'Department': department,
        'Section': section,
        'Cycle': selection
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> generateProcessingMergeWorkOrder(String address, String order, String userID, String department, String factory, String section) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/generateProcessingMergeWorkOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'UserID': userID,
        'Factory': factory,
        'Department': department,
        'Section': section
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> submitCuttingProgress(String address, String order, String userID, String department, String factory, String partID, dynamic selection, String type) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/submitCuttingProgress'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'UserID': userID,
        'Factory': factory,
        'Department': department,
        'Type': type,
        'PartID': partID,
        'Cycle': selection
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> submitProcessingProgress(String address, String order, String userID, String department, String factory, String section, dynamic selection) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/submitProcessingProgress'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'UserID': userID,
        'Factory': factory,
        'Department': department,
        'Section': section,
        'Cycle': selection
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getCuttingWorkOrder(String address, String date, String userID, String type) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getCuttingWorkOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Date': date,
        'UserID': userID,
        'Type': type
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> getOrderCuttingTrackingData(String address, String order, String type) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getOrderCuttingTrackingData'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'Type': type
      })
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> getOrderProcessingTrackingData(String address, String order, String type) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getOrderProcessingTrackingData'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'Type': type
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> getMaterialRequisitionCard(String address, String date, String building) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getMaterialRequisitionCard'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Date': date,
        'Building': building
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> getLeanScheduleRY(String address, String date, String building, String lean) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getLeanScheduleRY'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Date': date,
        'Building': building,
        'Lean': lean
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> getRYMaterials(String address, String ry, String section) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getRYMaterials'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'RY_Begin': ry,
        'Section': section
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> generateMRCard(String address, String section, String building, String lean, String date, String time, String source, String remark, String requestString, String userID, String factory) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/generateMRCard'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Section': section,
        'Building': building,
        'Lean': lean,
        'DemandDate': date,
        'DemandTime': time,
        'Source': source,
        'Remark': remark,
        'RequestString': requestString,
        'UserID': userID,
        'Factory': factory
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> updateMRCard(String address, String listNo, String section, String building, String lean, String date, String time, String source, String remark, String requestString, String userID, String factory) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/updateMRCard'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'ListNo': listNo,
        'Section': section,
        'Building': building,
        'Lean': lean,
        'DemandDate': date,
        'DemandTime': time,
        'Source': source,
        'Remark': remark,
        'RequestString': requestString,
        'UserID': userID,
        'Factory': factory
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> deleteMRCard(String address, String listNo) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/deleteMRCard'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'ListNo': listNo
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> signMRCard(String address, String listNo, String userID) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/signMRCard'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'ListNo': listNo,
        'UserID': userID
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getMRCardInfo(String address, String listNo) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getMRCardInfo'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'ListNo': listNo
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> getMonthStitchingOrder(String address, String lean, String month, String type, String order) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getMonthStitchingOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Lean': lean,
        'PlanMonth': month,
        'Type': type,
        'Order': order
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> getMonthAssemblyOrder(String address, String lean, String month, String type, String order) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getMonthAssemblyOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Lean': lean,
        'PlanMonth': month,
        'Type': type,
        'Order': order
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> getOrderCycleDispatchData(String address, String order, String section) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getOrderCycleDispatchData'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'Section': section
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> generateOrderCycleDispatchData(String address, String order, String section, String userID, String department, String factory, dynamic selection, String type, String date, int pairs, String remark) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/generateOrderCycleDispatchData'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'Section': section,
        'UserID': userID,
        'Factory': factory,
        'Department': department,
        'SelectedCycle': selection,
        'Type': type,
        'Date': date,
        'Pairs': pairs,
        'Remark': remark
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> getDailyMaterialUsage(String address, String section, String factory, String lean, String date) async {
    final response = await http.post(
        Uri.parse('$address/api/ERP/getDailyMaterialUsage'),
        headers: {
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'Section': section,
          'Building': factory,
          'Lean': lean,
          'Date': date
        })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> getOrderGroupDispatchPart(String address, String order, String machineType) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getOrderGroupDispatchPart'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'MachineType': machineType
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> getOrderGroupDispatchCycle(String address, String order, String part, String section) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getOrderGroupDispatchCycle'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'PartID': part,
        'Section': section
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> generateCuttingGroupWorkOrder(String address, String order, String part, String cycle, String userID, String department, String factory, String type) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/generateCuttingGroupWorkOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'PartID': part,
        'SelectedCycle': cycle,
        'UserID': userID,
        'Factory': factory,
        'Department': department,
        'Type': type
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> submitCuttingGroupProgress(String address, String order, String partID, String cycle, String userID, String department, String factory, String type) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/submitCuttingGroupProgress'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'PartID': partID,
        'SelectedCycle': cycle,
        'UserID': userID,
        'Department': department,
        'Factory': factory,
        'Type': type
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getLastWorkingDay(String address, String date, String factory) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getLastWorkingDay'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Date': date,
        'Factory': factory
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getAutoCuttingWorkOrder(String address, String machine, String date, String type) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getAutoCuttingWorkOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'MachineID': machine,
        'PlanStartDate': date,
        'Type': type
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getRY(String address, String building, String lean, String sku, String ry) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getRY'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Building': building,
        'Lean': lean,
        'Model': sku,
        'RY': ry
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> generateAutoCuttingWorkOrder(String address, String date, String machine, String ry, String part, String cycle, String userID, String department, String factory) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/generateAutoCuttingWorkOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'PlanDate': date,
        'MachineID': machine,
        'RY': ry,
        'Part': part,
        'Cycle': cycle,
        'UserID': userID,
        'Department': department,
        'Factory': factory
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> updateAutoCuttingWorkOrder(String address, String listNo, String date, String machine, String ry, String part, String cycle, String userID, String department, String factory) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/updateAutoCuttingWorkOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'ListNo': listNo,
        'PlanDate': date,
        'MachineID': machine,
        'RY': ry,
        'Part': part,
        'Cycle': cycle,
        'UserID': userID,
        'Department': department,
        'Factory': factory
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> reportAutoCuttingWorkOrder(String address, String listNo, String userID) async {
    final response = await http.post(
        Uri.parse('$address/api/ERP/reportAutoCuttingWorkOrder'),
        headers: {
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'ListNo': listNo,
          'UserID': userID
        })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> deleteAutoCuttingWorkOrder(String address, String listNo) async {
    final response = await http.post(
        Uri.parse('$address/api/ERP/deleteAutoCuttingWorkOrder'),
        headers: {
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'ListNo': listNo
        })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getAutoCuttingWorkOrderInfo(String address, String listNo) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getAutoCuttingWorkOrderInfo'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'WorkOrder': listNo
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> setCuttingPart(String address, String ry, String part) async {
    final response = await http.post(
        Uri.parse('$address/api/ERP/setCuttingPart'),
        headers: {
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'RY': ry,
          'Part': part
        })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> setAutoCuttingPart(String address, String ry, String part) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/setAutoCuttingPart'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'RY': ry,
        'Part': part
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getLaborDemand(String address, String month, String building, String lean, String type) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getLaborDemand'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Month': month,
        'Building': building,
        'Lean': lean,
        'Type': type
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getModelStandard(String address, String month, String building) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getModelStandard'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Month': month,
        'Building': building
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getStockFittingPlan(String address, String date) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getStockFittingPlan'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Date': date
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getR2Plan(String address, String date) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getR2Plan'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Date': date
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getTestingPlan(String address, String date) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getTestingPlan'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Date': date
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> get3DayPlan(String address, String date, String building) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/get3DayPlan'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Date': date,
        'Building': building
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> get1DayPlan(String address, String date, String building) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/get1DayPlan'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Date': date,
        'Building': building
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getProductionSchedule(String address, String startDate, String endDate, String area, String building, String mode, String version, String orderDate) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getProductionSchedule'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'StartDate': startDate,
        'EndDate': endDate,
        'Area': area,
        'Building': building,
        'Mode': mode,
        'Version': version,
        'OrderDate': orderDate
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getScheduleVersion(String address, String startDate, String endDate, String area, String building) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getScheduleVersion'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'StartDate': startDate,
        'EndDate': endDate,
        'Area': area,
        'Building': building
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getStage1Date(String address, String version) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getStage1Date'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Version': version
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getDailyCycleList(String address, String date, String building, String lean) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getDailyCycleList'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Date': date,
        'Building': building,
        'Lean': lean,
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getCycleListData(String address, String listNo) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getCycleListData'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'ListNo': listNo
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> updateCycleDispatchList(String address, String listNo, String order, String section, String userID, String department, String factory, dynamic selection, String type, String date, int pairs, String remark) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/updateCycleDispatchList'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'ListNo': listNo,
        'Order': order,
        'Section': section,
        'UserID': userID,
        'Factory': factory,
        'Department': department,
        'SelectedCycle': selection,
        'Type': type,
        'Date': date,
        'Pairs': pairs,
        'Remark': remark
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> deleteCycleDispatchList(String address, String listNo, String section) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/deleteCycleDispatchList'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'ListNo': listNo,
        'Section': section
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> getEstimatedInfo(String address, String startDate, String endDate, String building, String mode) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getEstimatedInfo'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'StartDate': startDate,
        'EndDate': endDate,
        'Building': building,
        'Mode': mode
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'result': false});
    }
  }

  Future<String> getLeanScheduleData(String address, String month, String building, String lean, String section) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getLeanScheduleData'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Month': month,
        'Building': building,
        'Lean': lean,
        'Section': section
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getLeanRYMatStatus(String address, String ry, String section) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getLeanRYMatStatus'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'RY': ry,
        'Section': section
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getLeanRYSecondProcess(String address, String ry) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getLeanRYSecondProcess'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'RY': ry
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getLeanRYDefects(String address, String ry, String building, String lean, String section) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getLeanRYDefects'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'RY': ry,
        'Building': building,
        'Lean': lean,
        'Section': section
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getLeanWorkOrder(String address, String building, String lean, String ry, String section, String type, String date) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getLeanWorkOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Building': building,
        'Lean': lean,
        'RY': ry,
        'Section': section,
        'Type': type,
        'Date': date
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getMachineWorkOrder(String address, String machine, String order) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getMachineWorkOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Machine': machine,
        'Order': order
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getMachineDispatchedPart(String address, String machine, String order) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getMachineDispatchedPart'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Machine': machine,
        'Order': order
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getReportingOrderSize(String address, String order, String section, String type, String partID, String machine) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getReportingOrderSize'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'Section': section,
        'Type': type,
        'PartID': partID,
        'Machine': machine
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getReportingCycle(String address, String order, String section, String type) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getReportingCycle'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'Section': section,
        'Type': type
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> getReportingDispatchedSizeRun(String address, String order, String machine, String partID, String section, String type) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getReportingDispatchedSizeRun'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'Machine': machine,
        'PartID': partID,
        'Section': section,
        'Type': type
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      throw Exception('Http failed');
    }
  }

  Future<String> submitLeanSectionProgress(String address, String order, String section, String type, String cycle, String size, int shortage, String userID, String executeType) async {
    try {
      final response = await http.post(
        Uri.parse('$address/api/ERP/submitLeanSectionProgress'),
        headers: {
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'Order': order,
          'Section': section,
          'Type': type,
          'SelectedCycle': cycle,
          'SelectedSize': size,
          'Shortage': shortage,
          'UserID': userID,
          'ExecuteType': executeType
        })
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return response.body;
      }
      else {
        return json.encode({'statusCode': 400});
      }
    } catch (e) {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> submitMachineCuttingProgress(String address, String order, String machine, String partID, String cycle, String size, String type) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/submitMachineCuttingProgress'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Order': order,
        'Machine': machine,
        'PartID': partID,
        'SelectedCycle': cycle,
        'SelectedSize': size,
        'Type': type
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getBuildingMachine(String address, String building, String type) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getBuildingMachine'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Factory': building,
        'Type': type
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getMachineDispatchedWorkOrder(String address, String machine) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getMachineDispatchedWorkOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'MachineID': machine
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> generateMachineCuttingWorkOrder(String address, String machine, String ry, String part, String cycle, String userID) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/generateMachineCuttingWorkOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'MachineID': machine,
        'RY': ry,
        'Part': part,
        'Cycle': cycle,
        'UserID': userID
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> cancelMachineCuttingWorkOrder(String address, String machine, String ry) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/cancelMachineCuttingWorkOrder'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'MachineID': machine,
        'RY': ry
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getShippingPlan(String address, String date, String factory) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getShippingPlan'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Date': date,
        'Factory': factory
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getShipmentTrackingData(String address, String date, String building, String status) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getShipmentTrackingData'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Date': date,
        'Building': building,
        'Type': status
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getBuyModels(String address, String buy, String factory, String cuttingDie, String last, String sku, String ry) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getBuyModels'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'BuyNo': buy,
        'Factory': factory,
        'CuttingDie': cuttingDie,
        'Last': last,
        'SKU': sku,
        'RY': ry
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getBuySKUs(String address, String buy, String factory, String ryType, String cuttingDie, String filterLast, String filterSKU, String filterRY) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getBuySKUs'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'BuyNo': buy,
        'Factory': factory,
        'RYType': ryType,
        'CuttingDie': cuttingDie,
        'Last': filterLast,
        'SKU': filterSKU,
        'RY': filterRY
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getBuyRYs(String address, String factory, String buy, String ryType, String cuttingDie, String filterSKU, String filterRY) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getBuyRYs'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'Factory': factory,
        'BuyNo': buy,
        'RYType': ryType,
        'CuttingDie': cuttingDie,
        'SKU': filterSKU,
        'RY': filterRY
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }

  Future<String> getRYBom(String address, String ry) async {
    final response = await http.post(
      Uri.parse('$address/api/ERP/getRYBom'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'RY': ry
      })
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    }
    else {
      return json.encode({'statusCode': 400});
    }
  }
}