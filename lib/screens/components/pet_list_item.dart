import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';


class PetListItem extends StatelessWidget{

  const PetListItem({required this.animalName, required this.animalType, required this.animalAge});

  final String animalName;
  final String animalType;
  final int animalAge;
  
  @override
  Widget build(BuildContext context) {
    
    return Container(

      child: Row(
        children: [
          Icon(Icons.pets, size: 50,),
          SizedBox(width: 10,),
          Text('$animalName, a $animalAge year old $animalType'),
        
        ],
      )

    );
  }
}