const emojiIndexToName = [
  "beaming-face.png",
  "cloud.png",
  "face-spiral.png",
  "flushed-face.png",
  "grimacing-face.png",
  "grinning-face.png",
  "grinning-squinting.png",
  "heart.png",
  "pouting-face.png",
  "raised-eyebrow.png",
  "relieved-face.png",
  "savoring-food.png",
  "smiling-heart.png",
  "smiling-horns.png",
  "smiling-sunglasses.png",
  "smiling-tear.png",
  "smirking-face.png",
  "tears-of-joy.png",
];

const randomEmojiIndex = () => {
  return Math.floor(Math.random() * emojiIndexToName.length);
}

const randomEmojiIndexNot = (index: number) => {
  let newIndex = randomEmojiIndex();
  while (newIndex === index) {
    newIndex = randomEmojiIndex();
  }
  return newIndex;
}

export { emojiIndexToName, randomEmojiIndex, randomEmojiIndexNot };
