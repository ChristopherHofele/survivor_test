bool checkCollision(player, block) {
  final playerX = player.position.x;
  final playerY = player.position.y;
  final playerWidth = player.width;
  final playerHeight = player.height;

  final blockX = block.x;
  final blockY = block.y;
  final blockWidth = block.width;
  final blockHeight = block.height;

  /*final fixedX = player.scale.x < 0
      ? playerX - ( * 2) - playerWidth
      : playerX;
  final fixedY = block.isPlatform ? playerY + playerHeight : playerY;*/

  return (playerY - playerHeight / 2 < blockY + blockHeight &&
      playerY + playerHeight / 2 > blockY &&
      playerX - playerHeight / 2 < blockX + blockWidth &&
      playerX + playerWidth / 2 > blockX);
}

bool isCollisionHorizontal(player, block) {
  return (player.position.x + player.width / 2 >
          block.position.x + block.width ||
      player.position.x - player.width / 2 < block.position.x);
}
