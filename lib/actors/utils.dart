bool checkCollision(player, block) {
  final playerX = player.position.x;
  final playerY = player.position.y;
  final playerWidth = player.width;
  final playerHeight = player.height;

  final blockX = block.x;
  final blockY = block.y;
  final blockWidth = block.width;
  final blockHeight = block.height;

  return (playerY - playerHeight / 2 < blockY + blockHeight &&
      playerY + playerHeight / 2 > blockY &&
      playerX - playerHeight / 2 < blockX + blockWidth &&
      playerX + playerWidth / 2 > blockX);
}

bool isCollisionVertical(player, block, dt) {
  final double correctedX = player.position.x - player.velocity.x * dt;
  final playerY = player.position.y;
  final playerWidth = player.width;
  final playerHeight = player.height;

  final blockX = block.x;
  final blockY = block.y;
  final blockWidth = block.width;
  final blockHeight = block.height;

  return (playerY - playerHeight / 2 < blockY + blockHeight &&
      playerY + playerHeight / 2 > blockY &&
      correctedX - playerHeight / 2 < blockX + blockWidth &&
      correctedX + playerWidth / 2 > blockX);
}

bool isCollisionHorizontal(player, block, dt) {
  final playerX = player.position.x;
  final double correctedY = player.position.y - player.velocity.y * dt;
  final playerWidth = player.width;
  final playerHeight = player.height;

  final blockX = block.x;
  final blockY = block.y;
  final blockWidth = block.width;
  final blockHeight = block.height;

  double buffer = 0;

  buffer = player.velocity.y >= 0 ? -1 : 1;

  return (correctedY + buffer - playerHeight / 2 < blockY + blockHeight &&
      correctedY + buffer + playerHeight / 2 > blockY &&
      playerX - playerHeight / 2 < blockX + blockWidth &&
      playerX + playerWidth / 2 > blockX);
}
