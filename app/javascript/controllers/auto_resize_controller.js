import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="auto-resize"
export default class extends Controller {
  static targets = []

  connect() {
    // Auto-resize textarea on input
    this.resize()
  }

  resize() {
    const textarea = this.element
    if (textarea) {
      // Reset height to get accurate scrollHeight
      textarea.style.height = "auto"
      // Set height to scrollHeight (content height)
      textarea.style.height = `${textarea.scrollHeight}px`
    }
  }
}
