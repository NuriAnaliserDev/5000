import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../../../services/presence_service.dart';

class MapTeamPresenceLayer extends StatelessWidget {
  const MapTeamPresenceLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PresenceService>(
      builder: (context, presence, _) {
        return MarkerLayer(
          markers: presence.teamMembers.map((member) {
            return Marker(
              point: member.position,
              width: 50,
              height: 50,
              child: Tooltip(
                message: '${member.name}\n${member.role}',
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        member.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.person_pin_circle,
                        color: Colors.blue, size: 30),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
