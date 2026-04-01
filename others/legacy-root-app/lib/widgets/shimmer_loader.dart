import 'package:colastica_xi/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoader extends StatelessWidget {
  final int itemCount;
  final double height;

  const ShimmerLoader({
    super.key,
    this.itemCount = 5,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.cardBackground,
          highlightColor: AppColors.secondaryCard,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            height: height,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}

class ShimmerMatchCard extends StatelessWidget {
  const ShimmerMatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardBackground,
      highlightColor: AppColors.secondaryCard,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 20,
              width: 200,
              color: AppColors.secondaryCard,
            ),
            SizedBox(height: 12),
            Container(
              height: 16,
              width: 150,
              color: AppColors.secondaryCard,
            ),
            SizedBox(height: 12),
            Container(
              height: 40,
              width: 100,
              color: AppColors.primaryAccent,
            ),
          ],
        ),
      ),
    );
  }
}

