// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import "bootstrap"
import "bootstrap/dist/css/bootstrap"
import "@rails/request.js"
import * as bootstrap from "bootstrap"
import Rails from "@rails/ujs"
Rails.start()

document.addEventListener("turbo:load", () => {
  document.querySelectorAll('.dropdown-toggle').forEach(dropdownToggleEl => {
    new bootstrap.Dropdown(dropdownToggleEl)
  })
})
