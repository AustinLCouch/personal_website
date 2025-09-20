-- Insert seed data for portfolio projects
INSERT INTO projects (slug, title, category, short_desc, long_desc, github_url, live_url, featured, tags) VALUES
(
    'nine-lives-cat-sudoku',
    'Nine Lives: Cat Sudoku',
    'Rust',
    'A professional cat-themed Sudoku game with advanced features',
    'Built with Rust and Bevy, Nine Lives transforms the classic Sudoku experience with adorable ASCII cat art, professional-grade features, and delightful gameplay. Features include undo/redo system, smart hints, multi-theme support, comprehensive testing with 31+ tests, and clean MVC architecture.',
    'https://github.com/AustinLCouch/nine_lives',
    NULL,
    TRUE,
    '["Rust", "Bevy", "Game Development", "MVC Architecture", "ASCII Art", "Sudoku"]'
),
(
    'my-amie-clone',
    'Amie Calendar Clone',
    'Web Development',
    'A Next.js clone of the Amie calendar application',
    'Modern calendar application built with Next.js, featuring clean UI design and calendar functionality. Demonstrates proficiency in React, Next.js, and modern web development practices.',
    'https://github.com/AustinLCouch/my-amie-clone',
    NULL,
    TRUE,
    '["Next.js", "React", "TypeScript", "Web Development", "UI/UX"]'
),
(
    'guessing-game',
    'Rust Guessing Game',
    'Rust',
    'Classic number guessing game implementation in Rust',
    'A foundational Rust project implementing the classic number guessing game. Demonstrates Rust fundamentals including user input, random number generation, and basic control flow.',
    'https://github.com/AustinLCouch/guessing_game',
    NULL,
    FALSE,
    '["Rust", "CLI", "Beginner Project"]'
),
(
    'little-fella',
    'Little Fella',
    'Rust',
    'Rust project showcasing various programming concepts',
    'An experimental Rust project exploring different programming concepts and techniques in the Rust ecosystem.',
    'https://github.com/AustinLCouch/little_fella',
    NULL,
    FALSE,
    '["Rust", "Experimental"]'
),
(
    'personal-website',
    'Portfolio Website',
    'Web Development',
    'Modern portfolio website built with Rust and Axum',
    'This very website! A modern, responsive portfolio built with Rust, Axum web framework, htmx for dynamic interactions, and SQLite for data persistence. Features clean architecture, server-side rendering, and deployment-ready configuration for Raspberry Pi.',
    'https://github.com/AustinLCouch/personal_website',
    NULL,
    TRUE,
    '["Rust", "Axum", "htmx", "SQLite", "Web Development", "Portfolio"]'
);
