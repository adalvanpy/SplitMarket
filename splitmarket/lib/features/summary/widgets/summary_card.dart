import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {

  final String title;

  final String value;

  final IconData icon;

  const SummaryCard({

    super.key,

    required this.title,

    required this.value,

    required this.icon,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(20),

      margin: const EdgeInsets.only(
        bottom: 16,
      ),

      decoration: BoxDecoration(

        color:
            Theme.of(context)
                .cardColor,

        borderRadius:
            BorderRadius.circular(20),

        boxShadow: [

          BoxShadow(

            color:
                Colors.black.withOpacity(
              0.05,
            ),

            blurRadius: 10,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(

        children: [

          Container(

            padding:
                const EdgeInsets.all(14),

            decoration: BoxDecoration(

              color:
                  const Color(0xFFF0EDFF),

              borderRadius:
                  BorderRadius.circular(14),
            ),

            child: Icon(

              icon,

              color:
                  const Color(0xFF8E76F7),

              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(

                  title,

                  style: TextStyle(

                    fontSize: 14,

                    color: Theme.of(context)

                        .textTheme

                        .bodyMedium

                        ?.color,
                  ),
                ),

                const SizedBox(height: 6),

                Text(

                  value,

                  style: TextStyle(

                    fontSize: 22,

                    fontWeight:
                        FontWeight.bold,

                    color: Theme.of(context)

                        .textTheme

                        .bodyLarge

                        ?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}