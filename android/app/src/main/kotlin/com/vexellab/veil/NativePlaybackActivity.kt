package com.vexellab.veil

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.ui.PlayerView

@androidx.annotation.OptIn(androidx.media3.common.util.UnstableApi::class)
class NativePlaybackActivity : Activity() {
    private var player: ExoPlayer? = null
    private var lastPosition = 0L
    private var desiredPlaying = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        val url = intent.getStringExtra("url") ?: run { finish(); return }
        @Suppress("DEPRECATION", "UNCHECKED_CAST")
        val headers = intent.getSerializableExtra("headers") as? HashMap<String, String> ?: hashMapOf()
        val factory = DefaultHttpDataSource.Factory().setDefaultRequestProperties(headers)
        val engine = ExoPlayer.Builder(this).setMediaSourceFactory(DefaultMediaSourceFactory(factory)).build()
        player = engine
        val view = PlayerView(this)
        view.player = engine
        view.setShowSubtitleButton(true)
        setContentView(view)
        engine.setMediaItem(MediaItem.Builder().setUri(url).setMimeType(if (intent.getStringExtra("format") == "mp4") MimeTypes.VIDEO_MP4 else MimeTypes.APPLICATION_M3U8).build())
        engine.seekTo(savedInstanceState?.getLong("position") ?: intent.getLongExtra("position", 0L))
        engine.volume = intent.getFloatExtra("volume", 1f)
        desiredPlaying = savedInstanceState?.getBoolean("playing") ?: intent.getBooleanExtra("playing", false)
        engine.prepare()
        engine.playWhenReady = desiredPlaying
    }
    override fun onSaveInstanceState(outState: Bundle) {
        outState.putLong("position", player?.currentPosition ?: lastPosition)
        outState.putBoolean("playing", player?.playWhenReady ?: desiredPlaying)
        super.onSaveInstanceState(outState)
    }
    override fun onStop() {
        player?.let { lastPosition = it.currentPosition; desiredPlaying = it.playWhenReady; it.pause() }
        super.onStop()
    }
    override fun onStart() { super.onStart(); player?.playWhenReady = desiredPlaying }
    override fun finish() {
        setResult(RESULT_OK, Intent().putExtra("position", player?.currentPosition ?: lastPosition).putExtra("playing", player?.playWhenReady ?: desiredPlaying))
        player?.pause()
        super.finish()
    }
    override fun onDestroy() { player?.release(); player = null; super.onDestroy() }
}
