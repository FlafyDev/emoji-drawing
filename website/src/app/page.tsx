'use client'

import Image from 'next/image'
import styles from './page.module.css'
import { Avatar, Box, Button, Checkbox, Container, CssBaseline, FormControlLabel, TextField, Typography } from '@mui/material'
import { useEffect, useState } from 'react'
import { redirect, useRouter } from 'next/navigation'


export default function Home() {
  const router = useRouter()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')

  useEffect(() => {
    fetch('/api/isLogged', { method: 'POST' })
      .then((res) => {
        if (res.status === 200) {
          router.push("/draw")
        }
      })
  }, [router])


  return (
    <main>
      <Container component="main" maxWidth="xs">
        <CssBaseline />
        <Box
          sx={{
            marginTop: 8,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
          }}
        >
          <Typography component="h1" variant="h5">
            Emoji Drawing
          </Typography>
          <TextField
            margin="normal"
            fullWidth
            id="name"
            label="Name"
            name="name"
            autoComplete="name"
            autoFocus
            value={username}
            onChange={(event: React.ChangeEvent<HTMLInputElement>) => {
              setUsername(event.target.value);
            }}
            sx={{ mt: 3, mb: 0 }}
          />
          <TextField
            margin="normal"
            fullWidth
            name="password"
            label="Password"
            type="password"
            id="password"
            autoComplete="current-password"
            value={password}
            onChange={(event: React.ChangeEvent<HTMLInputElement>) => {
              setPassword(event.target.value);
            }}
            sx={{ mt: 1, mb: 1 }}
          />
          <Typography
            variant="subtitle2"
            align="center"
            color="text.secondary"
            component="p"
          >
            {"Don't input your real password, this is not secure."}
          </Typography>
          <Typography
            variant="subtitle2"
            align="center"
            color="text.secondary"
            component="p"
          >
            {error}
          </Typography>
          <Button
            fullWidth
            variant="contained"
            sx={{ mt: 1, mb: 1 }}
            onClick={() => {
              fetch('/api/login', {
                method: 'POST',
                body: JSON.stringify({
                  username: username,
                  password: password
                })
              })
                .then((res) => {
                  if (res.status === 200) {
                    router.push("/draw")
                  } else {
                    res.text().then((text) => {
                      setError(text ?? "");
                    })
                  }
                })
            }}
          >
            Login / Register
          </Button>
        </Box>
      </Container>
    </main>
  )
}
