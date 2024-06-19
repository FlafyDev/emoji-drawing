'use client';

import Image from 'next/image'
import styles from './page.module.css'
import { Avatar, Box, Button, Checkbox, Container, CssBaseline, FormControlLabel, Icon, TextField, ToggleButton, ToggleButtonGroup, Typography } from '@mui/material'
import { emojiIndexToName, randomEmojiIndex, randomEmojiIndexNot } from '@/utils/emoji'
import CanvasDraw from "react-canvas-draw";
import Canvas from '@/utils/canvas';
import EmojiEventsIcon from '@mui/icons-material/EmojiEvents';
import DeleteIcon from '@mui/icons-material/Delete';
import UndoIcon from '@mui/icons-material/Undo';
import CheckIcon from '@mui/icons-material/Check';
import { useEffect, useRef, useState } from 'react';
import { Logout } from '@mui/icons-material';
import { useRouter } from 'next/navigation';

export default function Draw() {
  const router = useRouter()
  const canvasRef = useRef<CanvasDraw>(null);
  const [predictedEmojiIndex, setPredictedEmojiIndex] = useState<number | null>(null);
  const [predictedConfidence, setPredictedConfidence] = useState<string>("");
  const [predictedMessage, setPredictedMessage] = useState("");
  const [username, setUsername] = useState("");
  const [model, setModel] = useState(2);
  const modelNames = [
    "CNN",
    "CNN + Transfer Learning",
    "CNN + Transfer Learning + Fine Tuning",
  ]
  const modelTypes = [
    "cnn",
    "transfer",
    "transfer-fine",
  ]

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
              {"Draw any emoji you want!"}
            </Typography>
            <Box sx={{ display: "flex", gap: "16px", justifyContent: "center", alignItems: "center", flexFlow: "row wrap" }}
            >
              {
                Array.from({ length: 18 }, (_, emojiIndex) => (
                  <img key={emojiIndex} src={`emojis/${emojiIndexToName[emojiIndex]}`} alt="Emoji" style={{ height: 25 }}></img>
                ))
              }
            </Box>
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
          <img
            src={`emojis/${emojiIndexToName[predictedEmojiIndex ?? 0]}`}
            alt="Emoji"
            style={{
              visibility: predictedEmojiIndex == null ? "hidden" : "visible",
              height: 80,
              marginBottom: -15,
            }}
          ></img>
          {
            predictedConfidence !== "" ?
              (<Typography
                variant="subtitle2"
                align="center"
                color="text.secondary"
                component="p"
                sx={{ mt: 1 }}
              >{predictedConfidence}<br /> </Typography>)
              : <></>
          }
          {
            predictedMessage !== "" ?
              (<Typography
                variant="subtitle2"
                align="center"
                color="text.secondary"
                component="p"
                sx={{ mt: 1 }}
              >{predictedMessage}<br /> </Typography>)
              : <></>
          }

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
              onPointerDown={async () => {
                // Send
                await fetch('/api/predictEmoji', {
                  method: 'POST',
                  body: JSON.stringify({
                    // @ts-ignore
                    emojiBase64: canvasRef.current?.getDataURL("png"),
                    modelType: modelTypes[model], 
                  })
                }).then(async (res) => {
                  const json = await res.json();
                  if (res.status === 200) {
                    if (json["message"] !== undefined) {
                      setPredictedMessage(json["message"] as string)
                      setPredictedConfidence("")
                      setPredictedEmojiIndex(null)
                      return
                    }

                    const emojiIndex = parseInt(json["index"])
                    const confidence = json["confidence"] as string

                    setPredictedMessage("")
                    setPredictedEmojiIndex(emojiIndex)
                    setPredictedConfidence(confidence)
                  } else {
                    setPredictedMessage(json["error"])
                  }
                }).catch((_err) => {
                  alert(`Error: while sending emoji. Emoji was not sent, refresh the site!`);
                });

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
              onPointerDown={async () => {
                await fetch('/api/logout', { method: 'POST' });
                router.push("/");
              }}
            >
              <Logout />
            </Button>
          </Box>
          <Box>
            <Typography
              variant="subtitle2"
              align="center"
              color="text.secondary"
              component="p"
              sx={{ mt: 0, mb: 1, }}
            >
              {"Models:"}
            </Typography>
            <ToggleButtonGroup
              color="primary"
              value={model}
              orientation="vertical"
              exclusive
              onChange={(e, v) => setModel(v)}
              aria-label="Platform"
              sx={{ mt: 0, mb: 5, }}
            >
              {modelNames.map((name, index) => (
                <ToggleButton key={index} value={index}>{name}</ToggleButton>
              ))}
            </ToggleButtonGroup>
          </Box>
        </Box>
      </Container>
    </main >
  )
}



