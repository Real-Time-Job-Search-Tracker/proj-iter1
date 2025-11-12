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
 ```
 ```bash
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
6.  **Create Users**
    This starts the Rails server (Puma) on `localhost:3000`.

    ```bash
    rails console
    ```
    You can add as many users as you want.
    ```bash
    User.create!(email: "email@example.com", password: "password", password_confirmation: "password")
    ```
    ```bash
    exit
    ```

7.  **Run the application:**
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

For any future updates, you only need to:

1.  Push new code: `git push heroku main`
2.  Run migrations *if* you added any new ones: `heroku run rails db:migrate`
