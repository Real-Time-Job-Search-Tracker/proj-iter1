# FlowTrack

This project is a submission for the "Engineering Software-as-a-Service" (Fall 2025) course, Group 11.

## 1\. Team Members

  * You Wu (yw4643)
  * Jiawen Lyu (jl7257)
  * Zhijing Wu (zw3155)
  * Robert Fornos (rf2830)

## 2\. Project Description

The modern job search is fragmented and requires unsustainable manual tracking. **FlowTrack** solves this by using the **employer's final "Apply" URL** as a unique anchor for each application.

Our platform automatically parses key metadata and feeds every application into a **live Sankey diagram**. This flow-first visualization replaces static lists, allowing users to instantly see bottlenecks and track progress from *Applied* to *Offer*.

## 3\. Tech Stack

  * **Framework:** Ruby on Rails (MVC)
  * **Database:** PostgreSQL
  * **Testing:** RSpec (TDD) & Cucumber (BDD)
  * **Deployment:** Heroku

## 4\. Live Deployment (Heroku)

The live SaaS prototype is deployed to Heroku:

`https://flowtrack-7b01930f8bf1.herokuapp.com`

## 5\. GitHub Repository

The source code is available on GitHub:

`https://github.com/Real-Time-Job-Search-Tracker/proj-iter1`

## 6\. Local Development Instructions

### Prerequisites

Before you begin, ensure you have the following installed:

  * A specific Ruby version (e.g., as defined in `.ruby-version`)
  * Bundler
  * PostgreSQL (must be running)


If PostgreSQL is not already installed and running, use the following commands:
 
 ```bash
 brew install postgresql
 brew services start postgresql
 ```

### Setup

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/Real-Time-Job-Search-Tracker/proj-iter1.git
    cd proj-iter1
    ```

2.  **Install dependencies:**
    This command installs all the required gems specified in the `Gemfile`.

    ```bash
    bundle install
    ```

3.  **Create and setup the database:**
    This creates the development and test databases and runs all migrations.

    ```bash
    rails db:create
    rails db:migrate
    ```

5.  **(Optional) Seed the database:**
    If your project has seed data, run this command:

    ```bash
    rails db:seed
    ```

6.  **Run the application:**
    This starts the Rails server (Puma) on `localhost:3000`.

    ```bash
    rails s
    ```

    You can now access the app at `http://localhost:3000`.

### Testing

1.  **Run RSpec (Unit/Model/Controller Tests):**
    This executes all tests in the `spec/` directory.

    ```bash
    bundle exec rspec
    ```

2.  **Run Cucumber (User Stories / Acceptance Tests):**
    This executes all features in the `features/` directory.

    ```bash
    bundle exec cucumber
    ```

## 7\. Heroku Deployment Instructions

### Prerequisites

  * You must have a Heroku account.
  * You must have the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli) installed.

### Initial Deployment

1.  **Log in to the Heroku CLI:**

    ```bash
    heroku login
    ```

2.  **Create a new Heroku application:**
    You can either let Heroku pick a name or specify your own.

    ```bash
    # Let Heroku pick a name
    heroku create

    # Or specify a name (must be unique)
    heroku create your-app-name-here
    ```

    This also adds a new `heroku` git remote to your local repository.

3.  **Provision a PostgreSQL Database:**
    Our app requires a database. This command adds the free `hobby-dev` tier.

    ```bash
    heroku addons:create heroku-postgresql:hobby-dev
    ```

4.  **Push your code to Heroku:**
    This pushes your `main` branch to Heroku. Heroku automatically detects it's a Rails app, runs `bundle install`, and precompiles assets.

    ```bash
    git push heroku main
    ```

5.  **Run database migrations on Heroku:**
    Your code is deployed, but the database is empty. This command runs the `db:migrate` task on the Heroku server.

    ```bash
    heroku run rails db:migrate
    ```

6.  **(Optional) Seed the production database:**
    If you need to seed your live database, run this command:

    ```bash
    heroku run rails db:seed
    ```

7.  **Open your application:**
    This will open your newly deployed application in your web browser.

    ```bash
    heroku open
    ```

### Subsequent Deploys

For any future updates, you only need to:

1.  Push your new code: `git push heroku main`
2.  Run migrations *if* you added any new ones: `heroku run rails db:migrate`
