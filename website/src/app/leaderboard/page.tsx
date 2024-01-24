'use client';

import Image from 'next/image'
import styles from './page.module.css'
import { Avatar, Box, Button, Checkbox, Container, CssBaseline, FormControlLabel, Icon, TextField, Typography } from '@mui/material'
import { emojiIndexToName, randomEmojiIndex, randomEmojiIndexNot } from '@/utils/emoji'
import CanvasDraw from "react-canvas-draw";
import Canvas from '@/utils/canvas';
import EmojiEventsIcon from '@mui/icons-material/EmojiEvents';
import DeleteIcon from '@mui/icons-material/Delete';
import UndoIcon from '@mui/icons-material/Undo';
import CheckIcon from '@mui/icons-material/Check';
import { useEffect, useRef, useState } from 'react';
import { SkipNext } from '@mui/icons-material';
import { useRouter } from 'next/navigation';

type LeaderboardEntry = {
  username: string,
  emoji_counter: number,
  emoji_rank: number
}

export default function Leaderboard() {
  const router = useRouter()
  const [board, setBoard] = useState<LeaderboardEntry[]>([]);

  useEffect(() => {
    fetch('/api/isLogged', { method: 'POST' })
      .then((res) => {
        if (res.status !== 200) {
          router.push("/")
        }
      }).finally(async () => {
        setBoard(await fetch('/api/leaderboard')
          .then((res) => res.json()))
      });
  }, [router])

  return (
    <main>
      <Container component="main" maxWidth="xs">
        <CssBaseline />
        <Box
          sx={{
            marginTop: 2,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
          }}
        >
          <Box sx={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            flexDirection: "column",
            mb: 2,
          }}>
            <Typography component="h1" variant="h5" fontWeight={"bold"} sx={{ mb: 1 }}>
              Leaderboard
            </Typography>
          </Box>
          {board.map((entry, i) => <Row key={i} entry={entry} />)}
        </Box>
        <Button
          fullWidth
          variant="contained"
          sx={{ mt: 1, mb: 1 }}
          onClick={() => {
            router.push("/predict")
          }}
        >
          Continue drawing
        </Button>
      </Container>
    </main>
  )
}

const Row = (props: { entry: LeaderboardEntry }) => {
  const entry = props.entry;
  return <Box sx={{
    display: "flex",
    alignItems: "center",
    justifyContent: "left",
    flexDirection: "row",
    backgroundColor: "#000000aa",
    width: "100%",
    padding: 1,
    boarderRadius: 32,
    mb: 2,
  }}>
    <MedalNumber num={entry.emoji_rank} />
    <Typography component="h1" variant="h5" fontWeight={"bold"} sx={{ ml: 1 }}>
      {entry.username}
    </Typography>
    <Box sx={{ flexGrow: 1 }} />
    <Typography variant="subtitle2" align="center" color="text.secondary" component="p" fontWeight={"bold"} sx={{ mb: 1 }}>
      Emojis drawn: {entry.emoji_counter}
    </Typography>
  </Box>

}

const MedalNumber = (props: { num: number }) => {
  const num = props.num;
  const color = num === 1 ? "gold" : num === 2 ? "silver" : num === 3 ? "peru" : "black";
  const size = 48;
  return <Box sx={{
    width: size,
    height: size,
    borderRadius: 999,
    backgroundColor: color,
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    fontWeight: "bold",
    color: "white",
    fontSize: 32 - (num > 9 ? 16 : 0),
  }}>
    <Box sx={{
      width: size,
      height: size,
      borderRadius: 999,
      backgroundColor: "#00000044",
      display: "flex",
      justifyContent: "center",
      alignItems: "center",
      fontWeight: "bold",
      color: "white",
    }}>
      <Box sx={{
        width: size - 16,
        height: size - 16,
        borderRadius: 999,
        backgroundColor: color,
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        fontWeight: "bold",
        color: "white",
        textShadow: "1px  1px 0   #000, -1px -1px 0   #000, 1px -1px 0   #000, -1px  1px 0   #000, 3px  3px 5px #333", shadow: 1,
      }}>
        {num}
      </Box>
    </Box>
  </Box>
}
