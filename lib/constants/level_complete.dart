import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LevelCompleteDialog extends StatelessWidget {
  final int level;
  final int reward;
  final int bonus;
  final bool isComplete;
  final bool adsReady;
  final VoidCallback onNextLevel;

  const LevelCompleteDialog({
    super.key,
    required this.level,
    required this.reward,
    required this.onNextLevel,
    required this.bonus,
    required this.isComplete,
    required this.adsReady,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: SizedBox(
          height: 320,
          child: isComplete
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        backgroundImage:
                            AssetImage('assets/images/checked.png'),
                        radius: 30,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "level_complete".tr(args: [level.toString()]),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "earned_reward".tr(args: [reward.toString()]),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        "earned_bonus".tr(args: [bonus.toString()]),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor:
                                  Colors.white, // foreground (text) color
                              backgroundColor: Theme.of(context)
                                  .primaryColor, // background color
                            ),
                            onPressed: onNextLevel,
                            child: Text(context.tr('next_level')),
                          ),
                          SizedBox(width: 10,),
                          adsReady ?  ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor:
                              Colors.white, // foreground (text) color
                              backgroundColor: Theme.of(context).colorScheme.secondary, // background color
                            ),
                            onPressed: onNextLevel,
                            child: const Text("Reward x2 (ads)", style: TextStyle(fontSize: 11),),
                          ): const SizedBox.shrink(),

                        ],
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          backgroundImage:
                              AssetImage('assets/images/failed.png'),
                          radius: 30,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "level_failed".tr(args: [level.toString()]),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          context.tr('level_time_up'),
                          style: const TextStyle(fontSize: 20),
                        ),
                        Text(
                          context.tr('please_retry'),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor:
                                Colors.white, // foreground (text) color
                            backgroundColor: Theme.of(context)
                                .primaryColor, // background color
                          ),
                          onPressed: onNextLevel,
                          child: Text(context.tr('retry_level')),
                        ),
                      ],
                    ),
                  ),
                ),
        ));
  }


}
