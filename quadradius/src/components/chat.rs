use crate::components::Player;
use bevy::prelude::*;
use serde::{Deserialize, Serialize};

/// Component for individual chat messages
#[derive(Component, Clone, Debug, PartialEq, Serialize, Deserialize)]
pub struct ChatMessage {
    pub content: String,
    pub author: Player,
    pub timestamp: f64,
}

impl ChatMessage {
    pub fn new(content: String, author: Player, timestamp: f64) -> Self {
        Self {
            content,
            author,
            timestamp,
        }
    }
}

/// Resource for managing chat state
#[derive(Resource, Clone, Debug, Default)]
pub struct ChatState {
    pub messages: Vec<ChatMessage>,
    pub current_input: String,
    pub max_messages: usize,
    pub is_minimized: bool,
    pub unread_count: usize,
}

impl ChatState {
    pub fn new() -> Self {
        Self {
            messages: Vec::new(),
            current_input: String::new(),
            max_messages: 100, // Keep last 100 messages
            is_minimized: false,
            unread_count: 0,
        }
    }

    pub fn add_message(&mut self, message: ChatMessage) {
        self.messages.push(message);

        // Increment unread count if chat is minimized
        if self.is_minimized {
            self.unread_count += 1;
        }

        // Keep only the most recent messages
        if self.messages.len() > self.max_messages {
            self.messages.remove(0);
        }
    }

    pub fn minimize(&mut self) {
        self.is_minimized = true;
    }

    pub fn maximize(&mut self) {
        self.is_minimized = false;
        self.unread_count = 0; // Clear unread count when maximized
    }

    pub fn toggle_minimized(&mut self) {
        if self.is_minimized {
            self.maximize();
        } else {
            self.minimize();
        }
    }

    pub fn get_messages(&self) -> &Vec<ChatMessage> {
        &self.messages
    }

    pub fn clear_input(&mut self) {
        self.current_input.clear();
    }

    pub fn set_input(&mut self, input: String) {
        self.current_input = input;
    }

    pub fn get_input(&self) -> &String {
        &self.current_input
    }

    pub fn message_count(&self) -> usize {
        self.messages.len()
    }
}

/// Component for chat UI elements
#[derive(Component)]
pub struct ChatPanel;

#[derive(Component)]
pub struct ChatScrollArea;

#[derive(Component)]
pub struct ChatInputField;

#[derive(Component)]
pub struct ChatSendButton;

#[derive(Component)]
pub struct ChatMessageText {
    pub message_index: usize,
}

#[derive(Component)]
pub struct ChatMinimizeButton;

#[derive(Component)]
pub struct ChatHeader;

#[derive(Component)]
pub struct ChatContentArea;

#[derive(Component)]
pub struct ChatUnreadIndicator;
