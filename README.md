# Personal Portfolio Website

A modern, responsive portfolio website built with Rust, showcasing my software development projects and skills. Features server-side rendering, dynamic interactions with htmx, and a professional design with dark/light theme support.

## 🚀 Live Demo

*Coming soon - deployment in progress*

## ✨ Features

- **Modern Tech Stack**: Rust + Axum web framework for blazing-fast performance
- **Server-Side Rendering**: Askama templates for SEO-friendly, fast-loading pages
- **Dynamic Interactions**: htmx for seamless user experience without JavaScript frameworks
- **Responsive Design**: Mobile-first approach with professional UI/UX
- **Dark/Light Themes**: User preference stored in localStorage
- **Database-Driven**: SQLite backend with migrations for easy deployment
- **Project Showcase**: Dynamic filtering and detailed project pages
- **Professional Monitoring**: Health checks and structured logging

## 🛠️ Tech Stack

- **Backend**: Rust 1.75+ with Axum web framework
- **Database**: SQLite with sqlx for type-safe queries
- **Frontend**: Server-side rendered HTML with htmx for interactivity
- **Templating**: Askama (Jinja2-like syntax)
- **Styling**: Modern CSS with custom properties and responsive design
- **Deployment**: Docker-ready, Raspberry Pi compatible

## 📋 Prerequisites

- Rust 1.75 or higher
- SQLite 3
- Git

## 🔧 Installation & Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/AustinLCouch/personal_website.git
   cd personal_website
   ```

2. **Install SQLx CLI** (for database migrations)
   ```bash
   cargo install sqlx-cli --features sqlite
   ```

3. **Set up the database**
   ```bash
   # Create the database
   sqlx database create --database-url sqlite:./portfolio.db
   
   # Run migrations
   sqlx migrate run --database-url sqlite:./portfolio.db
   ```

4. **Set environment variables**
   ```bash
   export DATABASE_URL=sqlite:./portfolio.db
   export RUST_LOG=info,personal_website=debug
   ```

5. **Run the development server**
   ```bash
   cargo run
   ```

6. **Visit the website**
   Open http://localhost:8080 in your browser

## 📁 Project Structure

```
personal_website/
├── src/
│   ├── main.rs              # Application entry point
│   ├── lib.rs               # Library modules
│   ├── config.rs            # Configuration management
│   ├── db.rs                # Database connection
│   ├── errors.rs            # Custom error types
│   ├── state.rs             # Application state
│   ├── models/              # Data models
│   │   ├── mod.rs
│   │   └── project.rs       # Project model with database queries
│   └── routes/              # HTTP request handlers
│       └── mod.rs           # Route handlers for all endpoints
├── templates/               # Askama HTML templates
│   ├── layout.html          # Base layout template
│   ├── home.html            # Homepage template
│   ├── projects.html        # Projects listing template
│   ├── project_detail.html  # Individual project template
│   ├── project_fragment.html # htmx fragment template
│   └── 404.html             # Error page template
├── static/                  # Static assets
│   ├── css/main.css         # Responsive CSS with theme support
│   └── js/htmx.min.js       # htmx library
├── migrations/              # Database migrations
│   ├── 20250920025018_create_projects.sql
│   └── 20250920025029_seed_projects.sql
├── Cargo.toml               # Rust dependencies
├── .env                     # Environment variables (development)
└── README.md                # This file
```

## 🌐 API Endpoints

- `GET /` - Homepage with featured projects
- `GET /projects` - All projects with optional category filtering
- `GET /projects?category=Rust` - Filter projects by category
- `GET /projects?fragment=true` - htmx fragment for dynamic loading
- `GET /project/{slug}` - Individual project details
- `GET /healthz` - Health check endpoint
- `GET /static/*` - Static file serving

## 🔄 Development Workflow

### Adding New Projects

1. Add project data via database migration or direct SQL:
   ```sql
   INSERT INTO projects (slug, title, category, short_desc, long_desc, github_url, featured, tags) 
   VALUES ('my-project', 'My Project', 'Rust', 'Short description', 'Long description', 'https://github.com/...', true, '["Rust", "Web"]');
   ```

2. The project will automatically appear on the website

### Database Migrations

```bash
# Create a new migration
sqlx migrate add migration_name

# Run migrations
sqlx migrate run

# Revert last migration
sqlx migrate revert
```

### Development Commands

```bash
# Run with auto-reload (install cargo-watch first)
cargo watch -x run

# Run tests
cargo test

# Check code without building
cargo check

# Format code
cargo fmt

# Run clippy lints
cargo clippy
```

## 🚀 Deployment

### Local Production Build

```bash
cargo build --release
export DATABASE_URL=sqlite:./portfolio.db
./target/release/personal_website
```

### Docker Deployment

*Docker configuration coming soon*

### Raspberry Pi Deployment

*Detailed Pi deployment guide in progress*

## 🎨 Customization

### Adding Your Own Projects

Edit the seed migration or add projects directly to the database. Each project supports:
- Title, category, and descriptions
- GitHub and live demo URLs
- Technology tags (JSON array)
- Featured status for homepage display

### Styling

- CSS custom properties in `static/css/main.css`
- Dark/light theme variables
- Responsive breakpoints
- Modern design system

### Content

- Update personal information in templates
- Modify skills section in `templates/home.html`
- Customize contact information in `templates/layout.html`

## 📊 Features in Detail

### htmx Integration
- Progressive enhancement (works without JavaScript)
- Dynamic project filtering without page reloads
- Smooth user experience with minimal client-side code

### Database Design
- Normalized schema with indexes for performance
- Automatic timestamps with triggers
- JSON tags for flexible categorization

### Performance
- Server-side rendering for fast initial load
- Static file serving with proper caching headers
- Efficient SQLite queries with connection pooling

## 🤝 Contributing

While this is a personal portfolio, suggestions and improvements are welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - feel free to use this code for your own portfolio!

## 🔗 Connect With Me

- **GitHub**: [AustinLCouch](https://github.com/AustinLCouch)
- **Email**: austinlcouch@gmail.com
- **Portfolio**: *This website!*

---

**Built with ❤️ using Rust, Axum, and htmx**