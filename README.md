# Empire Flippers to HubSpot Integration

This project implements an automated Background Job in Ruby on Rails designed to sync listings from the **Empire Flippers** API and automatically create them as Deals in **HubSpot**.

Below is a breakdown of the project's core structure, specifically explaining the 5 crucial files that make this integration possible, their purpose, and where they are located.

## 📂 Main Files

### 1. The Background Job
**Location:** `app/jobs/sync_empire_flippers_deals_job.rb`

This is the main engine of the integration. It is a Ruby class that includes Sidekiq to run in the background (asynchronously). 
* **What it does:** 
  - Connects to the Empire Flippers API and paginates through its results to extract multiple real listings (both "Sold" and "For Sale").
  - Connects to the HubSpot API using the `hubspot-api-client` gem and the API key saved in the environment variables (`ENV`).
  - Iterates over the results and registers each deal in HubSpot, mapping pricing information and details to the sales Pipeline.
  - Stores a local record in the database preventing deals from being duplicated in HubSpot if the sync runs again.

### 2. The Database Model
**Location:** `app/models/listing.rb`

This file defines the Ruby representation of a local record for the database table.
* **What it does:** It inherits from ActiveRecord and interacts with the PostgreSQL (or SQLite) engine. It is responsible for reading and successfully saving the `listing_number`, `price`, and `status`. Thanks to the persistence of this model, when the sync code asks *"Did we already sync listing 92814?"*, Rails queries the database and instantly responds so it can skip the API call.

### 3. The Database Migration
**Location:** `db/migrate/20260326000000_create_listings.rb` (or similar timestamp)

This file acts as the architect's blueprint for the database.
* **What it does:** It contains the instructions that Rails uses to physically create the `listings` table from scratch. It specifies exactly which columns must exist (such as making `listing_number` a text string, setting the `price`, and adding the respective `created_at`/`updated_at` timestamps), ensuring structural integrity if another developer installs this project from scratch.

### 4. Sidekiq Schedule Configuration
**Location:** `config/sidekiq.yml`

Unlike the Job itself, this is the YAML-formatted configuration file that manages the pipelines (Queues) and scheduled routines.
* **What it does:** When combined with gems like `sidekiq-scheduler`, it allows us to schedule a specific CronJob. This is where the Rails system is instructed to automatically run the `SyncEmpireFlippersDealsJob` class on a recurring basis (e.g., daily) without a human having to press any buttons.

### 5. Automated Unit Tests (RSpec)
**Location:** `spec/sync_empire_flippers_deals_job_spec.rb`

This is the automated Quality Assurance (QA) testing system that verifies everything works without needing to open a browser.
* **What it does:** It tests our Job's behavior by artificially simulating (using WebMock or "Doubles") what the Empire Flippers API would respond, and spoofing the HubSpot Client interface. This instantly validates two vital business rules without altering the real production database:
  1. That the record creation request is accurately sent to HubSpot only once, and that it is saved to the local Database when receiving entirely new listings.
  2. That no asynchronous web requests are fired to the external API if it detects that the listing was already saved in a previous run.

---

## 🚀 How to Execute or Test this Flow

To manually test in development mode using the console:

```ruby
# Forcibly executes the job synchronously, simulating Sidekiq's trigger
SyncEmpireFlippersDealsJob.new.perform; nil
```

To run the unit tests and verify that the asynchronous flow and logic are flawless:
```bash
bundle exec rspec spec/sync_empire_flippers_deals_job_spec.rb
```
