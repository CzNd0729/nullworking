import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/comment.dart';

class CommentList extends StatelessWidget {
  final List<Comment> comments;
  final int? currentUserId;
  final Function(Comment)? onReply;
  final Function(int)? onDelete;

  const CommentList({
    super.key,
    required this.comments,
    this.currentUserId,
    this.onReply,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 12),
              Text(
                '暂无评论',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return _CommentItem(
          comment: comment,
          currentUserId: currentUserId,
          onReply: onReply,
          onDelete: onDelete,
        );
      },
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Comment comment;
  final int? currentUserId;
  final Function(Comment)? onReply;
  final Function(int)? onDelete;

  const _CommentItem({
    required this.comment,
    this.currentUserId,
    this.onReply,
    this.onDelete,
  });

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return DateFormat('MM-dd HH:mm').format(time);
    }
  }

  Widget _buildContent() {
    // 直接显示评论内容，不再高亮@用户
    return Text(comment.content, style: const TextStyle(color: Colors.white70));
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUserId != null && currentUserId == comment.userId;

    return InkWell(
      onTap: onReply != null ? () => onReply!(comment) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[800]!, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息行
            Row(
              children: [
                // 头像
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF2CB7B3),
                  child: Text(
                    comment.userName.isNotEmpty
                        ? comment.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 用户名
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatTime(comment.createTime),
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // 删除按钮（仅评论作者可见）
                if (isOwner && onDelete != null && comment.commentId != null)
                  InkWell(
                    onTap: () => onDelete!(comment.commentId!),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // 回复标识（如果是回复某人的评论）
            if (comment.replyToUserName != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.subdirectory_arrow_right,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '回复 ${comment.replyToUserName}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            // 评论内容
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }
}
