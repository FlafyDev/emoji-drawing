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

export default function Draw() {
  const router = useRouter()
  const canvasRef = useRef<CanvasDraw>(null);
  const focusRef = useRef<HTMLButtonElement>(null);
  const [emojiIndex, setEmojiIndex] = useState(randomEmojiIndex());
  const [username, setUsername] = useState("");

  useEffect(() => {
    fetch('/api/isLogged', { method: 'POST' })
      .then(async (res) => {
        if (res.status !== 200) {
          router.push("/")
          return;
        }
        setUsername(await res.text());
      })
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
              Draw
            </Typography>
            <img src={`emojis/${emojiIndexToName[emojiIndex]}`} alt="Emoji" style={{ height: 80 }}></img>
          </Box>

          <CanvasDraw
            ref={canvasRef}
            lazyRadius={0}
            brushRadius={7}
            style={{ position: 'relative' }}
            backgroundColor='white'
            hideGrid={true}
            immediateLoading={true}
            loadTimeOffset={0}
            catenaryColor='transparent'
            hideInterface={true}
          // onChange={() => {
          //   // focusRef.current?.click();
          //   document.getElementById("button")?.focus();
          //   console.log("CHANGED");
          // }}

          />

          <Typography
            variant="subtitle2"
            align="center"
            color="text.secondary"
            component="p"
            sx={{ mt: 1 }}
          >
            Player name: {username}<br />

          </Typography>

          <Box sx={{ width: '100%', display: "flex", gap: "16px", justifyContent: "center", alignItems: "center", flexDirection: "row" }}>
            <Button
              sx={{ mt: 1, mb: 1, aspectRatio: 1, }}
              onPointerDown={() => {
                canvasRef.current?.clear();
                canvasRef.current?.clear();
                canvasRef.current?.clear();
                canvasRef.current?.clear();
              }}
            >
              <DeleteIcon />
            </Button>
            <Button
              sx={{ mt: 1, mb: 1, aspectRatio: 1, }}
              onPointerDown={() => {
                canvasRef.current?.undo();
              }}
            >
              <UndoIcon />
            </Button>
            <Button
              sx={{ mt: 1, mb: 1, aspectRatio: 1, pointerEvents: "all" }}
              color="success"
              onPointerDown={() => {
                // Send
                fetch('/api/send', {
                  method: 'POST',
                  body: JSON.stringify({
                    // @ts-ignore
                    emojiBase64: canvasRef.current?.getDataURL("png"),
                    emojiId: emojiIndex,
                  })
                }).then(async (res) => {
                  if (res.status !== 200) {
                    alert(`Error: ${await res.text()}. Emoji was not sent, refresh the site!`);
                  }
                }).catch((_err) => {
                    alert(`Error: while sending emoji. Emoji was not sent, refresh the site!`);
                });

                // Next
                setEmojiIndex(randomEmojiIndexNot(emojiIndex));
                canvasRef.current?.clear();
                canvasRef.current?.clear();
                canvasRef.current?.clear();
                canvasRef.current?.clear();
              }}
            >
              <CheckIcon />
            </Button>
            <Button
              sx={{ mt: 1, mb: 1, aspectRatio: 1, }}
              onPointerDown={() => {
                router.push("/leaderboard")
              }}
            >
              <EmojiEventsIcon />
            </Button>
            <Button
              sx={{ mt: 1, mb: 1, aspectRatio: 1, }}
              color="error"
              onPointerDown={() => {
                setEmojiIndex(randomEmojiIndexNot(emojiIndex));
                canvasRef.current?.clear();
                canvasRef.current?.clear();
                canvasRef.current?.clear();
                canvasRef.current?.clear();
              }}
            >
              <SkipNext />
            </Button>
          </Box>
        </Box>
      </Container>
    </main>
  )
}


