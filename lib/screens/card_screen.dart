import 'package:flutter/material.dart';

import '../database_helper.dart';

import '../models/card.dart';
import '../models/folder.dart';

import '../repositories/folder_repository.dart';
import '../../repositories/card_repository.dart';

class CardsScreen extends StatefulWidget {
  final Folder folder;

  CardsScreen({required this.folder});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final CardRepository _cardRepository = CardRepository();
  List<Card> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future _loadCards() async {
    final cards = await _cardRepository.getCardsByFolderId(widget.folder.id!);
    setState(() {
      _cards = cards.cast<Card>();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}