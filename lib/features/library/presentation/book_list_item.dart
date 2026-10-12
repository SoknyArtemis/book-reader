import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/book.dart';

/// 书架中的单本书条目。
class BookListItem extends StatelessWidget {
  const BookListItem({super.key, required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.menu_book_outlined),
      title: Text(book.title),
      subtitle: Text(book.author ?? book.format.label),
      trailing: Chip(
        label: Text(book.format.label),
        visualDensity: VisualDensity.compact,
      ),
      onTap: () => context.push('/reader', extra: book),
    );
  }
}
