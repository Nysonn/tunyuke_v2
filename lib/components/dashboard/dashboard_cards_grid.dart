import 'package:Tunyuke/components/dashboard/dashboard_action_card.dart';
import 'package:flutter/material.dart';

class DashboardCardsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> cardsData;
  final List<Animation<double>> cardAnimations;
  final Function(String routeName) onCardTapped;

  const DashboardCardsGrid({
    Key? key,
    required this.cardsData,
    required this.cardAnimations,
    required this.onCardTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      children: List.generate(cardsData.length, (index) {
        final card = cardsData[index];
        return DashboardActionCard(
          animation: cardAnimations[index],
          icon: card['icon'],
          title: card['title'],
          subtitle: card['subtitle'],
          info: card['info'],
          onTap: () => onCardTapped(card['route']),
          gradientColors: card['gradientColors'],
        );
      }),
    );
  }
}
