# FlowTrack

This project is a submission for the "Engineering Software-as-a-Service" (Fall 2025) course, Group 11.

## 1\. Team Members

  * You Wu (yw4643)
  * Jiawen Lyu (j17257)
  * Zhijing Wu (zw3155)
  * Robert Fornos (rf2830)

## 2\. Project Description

The modern job search is fragmented and requires unsustainable manual tracking. **FlowTrack** solves this by using the **employer's final "Apply" URL** as a unique anchor for each application.

Our platform automatically parses key metadata and feeds every application into a **live Sankey diagram**. This flow-first visualization replaces static lists, allowing users to instantly see bottlenecks and track progress from *Applied* to *Offer*. The system is built on **Ruby on Rails** with TDD/BDD practices.

## 3\. Live Deployment (Heroku)

The live SaaS prototype is deployed to Heroku:

`[INSERT YOUR HEROKU DEPLOYMENT LINK HERE]`

## 4\. GitHub Repository

The source code is available on GitHub:

`[INSERT YOUR GITHUB REPOSITORY LINK HERE]`

## 5\. Instructions to Run and Test

### Local Setup

1.  **Clone the repository:**
    ```bash
    git clone [INSERT YOUR GITHUB REPOSITORY LINK HERE]
    cd flowtrack
    ```
2.  **Install dependencies:**
    ```bash
    bundle install
    ```
3.  **Setup the database:**
    ```bash
    rails db:create
    rails db:migrate
    ```
4.  **Run the application:**
    ```bash
    rails s
    ```
    Access the app at `http://localhost:3000`.

### Testing

1.  **Run RSpec (Unit Tests):**
    ```bash
    bundle exec rspec
    ```
2.  **Run Cucumber (User Stories / Feature Tests):**
    ```bash
    bundle exec cucumber
    ```
