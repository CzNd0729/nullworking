import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/log.dart';
import '../../models/comment.dart';
import '../../services/business/log_business.dart';
import '../../services/business/comment_business.dart';
import 'create_log_page.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart'; // Add shared_preferences import
import 'package:webview_flutter/webview_flutter.dart'; // Add webview_flutter import
import '../../widgets/comment_list.dart';
import '../../widgets/comment_input.dart';

class LogDetailPage extends StatefulWidget {
  final String logId;

  const LogDetailPage({super.key, required this.logId});

  @override
  State<LogDetailPage> createState() => _LogDetailPageState();
}

class _LogDetailPageState extends State<LogDetailPage> {
  final LogBusiness _logBusiness = LogBusiness();
  final CommentBusiness _commentBusiness = CommentBusiness();
  Log? _logDetails;
  List<Map<String, dynamic>> _logFiles = [];
  List<Comment> _comments = [];
  bool _isLoading = true;
  int? _currentUserId;
  Comment? _replyToComment;
  WebViewController? _mapController; // Add WebViewController
  double? _latitude; // Add latitude
  double? _longitude; // Add longitude
  String? _address; // Add address variable
  bool _showLocationInfo = false; // Add this state variable

  @override
  void initState() {
    super.initState();
    _fetchLogData();
    _loadCurrentUser();
    _loadComments();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdString = prefs.getString('userId');
    if (userIdString != null) {
      setState(() {
        _currentUserId = int.tryParse(userIdString);
      });
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _commentBusiness.getCommentsByLogId(widget.logId);
      setState(() {
        _comments = comments;
      });
    } catch (e) {
      debugPrint('加载评论失败: $e');
    }
  }

  // Function to update the map location in the WebView
  void _updateMapLocation(double latitude, double longitude) {
    _mapController?.runJavaScript(
        'updateLocation($latitude, $longitude)');
  }

  Future<void> _fetchLogData() async {
    try {
      setState(() => _isLoading = true);
      final log = await _logBusiness.fetchLogDetails(widget.logId);
      if (log != null) {
        setState(() {
          _logDetails = log;
          _latitude = log.latitude;
          _longitude = log.longitude;
          if (log.latitude != null && log.longitude != null) {
            _showLocationInfo = true;
            _mapController = WebViewController();
            _mapController!.loadFlutterAsset('assets/map.html').then((value) {
              _updateMapLocation(_latitude!, _longitude!); // Update map if location already available
            });
            _mapController!.setJavaScriptMode(JavaScriptMode.unrestricted);
            _mapController!.setNavigationDelegate(NavigationDelegate(
              onPageFinished: (String url) {
                _updateMapLocation(_latitude!, _longitude!); // Update map if location already available
              },
            ));

            _mapController!.addJavaScriptChannel(
              'FlutterMapChannel',
              onMessageReceived: (message) {
                setState(() {
                  _address = message.message;
                });
              },
            );
          }
        });

        if (log.fileIds != null && log.fileIds!.isNotEmpty) {
          final files = await _logBusiness.fetchLogFiles(log.fileIds!);
          setState(() {
            _logFiles = files;
          });
        }
      } else {
        // Handle case where log is not found
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('日志详情加载失败！')));
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('加载日志详情异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载日志详情失败: ${e.toString()}')));
        Navigator.of(context).pop();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2CB7B3)),
        ),
      );
    }

    if (_logDetails == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('未能加载日志详情', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final log = _logDetails!;
    String statusText;
    switch (log.logStatus) {
      case 0:
        statusText = '未完成';
        break;
      case 1:
        statusText = '已完成';
        break;
      default:
        statusText = '未知';
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('日志详情'),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 关键修改：已完成日志的编辑按钮禁用+灰色
          IconButton(
            icon: Icon(
              Icons.edit,
              // 未完成显示白色，已完成显示灰色
              color:
                  _logDetails?.logStatus == 0 &&
                      _logDetails?.userId == _currentUserId
                  ? Colors.white
                  : Colors.grey[500],
            ),
            // 仅当日志未完成（logStatus == 0）时可点击
            onPressed:
                _logDetails?.logStatus == 0 &&
                    _logDetails?.userId == _currentUserId
                ? () => _editLog(context)
                : null,
          ),
          IconButton(
            icon: Icon(
              Icons.delete,
              // 未完成显示红色，已完成显示灰色
              color:
                  _logDetails?.logStatus == 0 &&
                      _logDetails?.userId == _currentUserId
                  ? Colors.redAccent
                  : Colors.grey[500],
            ),
            // 仅当日志未完成（logStatus == 0）时可点击
            onPressed:
                _logDetails?.logStatus == 0 &&
                    _logDetails?.userId == _currentUserId
                ? () => _confirmDeleteLog(context)
                : null,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.logTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          log.logContent,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '日志概览',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.calendar_today,
                          '日期',
                          DateFormat('yyyy年MM月dd日').format(log.logDate),
                        ),
                        const SizedBox(height: 8),
                        if (log.userName != null &&
                            log.userName!.isNotEmpty) ...[
                          _buildInfoRow(
                            Icons.person_outline,
                            '创建者',
                            log.userName!,
                          ),
                          const SizedBox(height: 8),
                        ],
                        _buildInfoRow(Icons.access_time, '开始时间', log.startTime),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.access_time, '结束时间', log.endTime),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.info_outline, '状态', statusText),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 新增的任务信息卡片
                  if (log.taskId != null ||
                      log.taskTitle != null ||
                      log.taskProgress != null)
                    GestureDetector(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '关联任务信息',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (log.taskId != null)
                              _buildInfoRow(
                                Icons.assignment,
                                '任务',
                                log.taskTitle ?? log.taskId.toString(),
                              ),
                            if (log.taskId != null) const SizedBox(height: 8),
                            if (log.taskProgress != null)
                              _buildInfoRow(
                                Icons.data_usage,
                                '任务进度',
                                '${log.taskProgress ?? 0}%',
                              ),
                          ],
                        ),
                      ),
                    ),
                  // 文件附件区域
                  if (_logFiles.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '附件',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 100, // 固定高度以便横向滚动
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _logFiles.length,
                              itemBuilder: (context, index) {
                                final fileData = _logFiles[index];
                                final fileBytes =
                                    fileData['fileBytes'] as Uint8List?;
                                final fileName =
                                    fileData['fileName'] as String? ?? '未知文件';

                                Widget contentWidget;
                                if (fileBytes != null) {
                                  contentWidget = Image.memory(
                                    fileBytes,
                                    fit: BoxFit.cover,
                                  );
                                } else {
                                  contentWidget = Center(
                                    child: Text(
                                      fileName,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  );
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: GestureDetector(
                                    onTap: () => _previewImage(
                                      fileBytes,
                                      fileName,
                                    ), // 调用预览功能
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors
                                            .grey[800], // Placeholder background
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: contentWidget,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_showLocationInfo && _latitude != null && _longitude != null) // Conditionally render location info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '定位信息',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200, // Adjust height as needed
                            child: _mapController != null
                                ? WebViewWidget(
                                    controller: _mapController!,
                                  )
                                : const Center(child: CircularProgressIndicator()),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '经度: ${_longitude!.toStringAsFixed(6)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '纬度: ${_latitude!.toStringAsFixed(6)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '地址: ${_address ?? '未获取'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  // 评论区
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.comment,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '评论 (${_comments.length})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CommentList(
                          comments: _comments,
                          currentUserId: _currentUserId,
                          onReply: (comment) {
                            setState(() {
                              _replyToComment = comment;
                            });
                          },
                          onDelete: _deleteComment,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80), // 为底部输入框留出空间
                ],
              ),
            ),
          ),
          // 底部评论输入框
          CommentInput(
            replyTo: _replyToComment,
            onCancelReply: () {
              setState(() {
                _replyToComment = null;
              });
            },
            onSubmit: _submitComment,
          ),
        ],
      ),
    );
  }

  void _previewImage(Uint8List? imageBytes, String fileName) {
    if (imageBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法预览文件')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero, // 使对话框全屏
        child: Stack(
          children: [
            Center(
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editLog(BuildContext context) async {
    // 额外判断：如果日志已完成，直接提示并返回
    if (_logDetails?.logStatus == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已完成的日志不可修改'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final updatedLog = await Navigator.push<Log?>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateLogPage(logToEdit: _logDetails),
      ),
    );

    if (updatedLog != null) {
      // 如果日志被更新，则重新加载日志详情
      _fetchLogData();
    }
  }

  Future<void> _confirmDeleteLog(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('确认删除', style: TextStyle(color: Colors.white)),
          content: const Text(
            '您确定要删除此日志吗？',
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                '取消',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '删除',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteLog();
    }
  }

  Future<void> _deleteLog() async {
    final Map<String, dynamic> result = await _logBusiness.deleteLog(
      _logDetails!.logId,
    );
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日志删除成功！'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true); // 返回并告知前一个页面已删除
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('日志删除失败: ${result['message']}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _submitComment(String content) async {
    final result = await _commentBusiness.createComment(
      logId: widget.logId,
      content: content,
      mentionedUsers: null,
      replyToId: _replyToComment?.commentId,
      replyToUserName: _replyToComment?.userName,
    );

    if (result['success'] == true) {
      // 清除回复状态
      setState(() {
        _replyToComment = null;
      });

      // 重新加载评论列表
      _loadComments();

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('评论成功'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? '评论失败'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('确认删除', style: TextStyle(color: Colors.white)),
          content: const Text(
            '确定要删除这条评论吗？',
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                '取消',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '删除',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final result = await _commentBusiness.deleteComment(commentId);

      if (result['success'] == true) {
        // 重新加载评论列表
        _loadComments();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '删除失败'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
