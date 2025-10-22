import { Controller } from "stimulus";
import L from "leaflet";
import LeafetProviders from "leaflet-providers";
import { OpenStreetMapProvider } from "leaflet-geosearch";

export default class extends Controller {
  static targets = ["confirmAddressField", "dragPinNote"];
  static values = {
    defaultLatitude: Number,
    defaultLongitude: Number,
    providerName: String,
    providerOptions: Object,
  };

  connect() {
    this.zoomLevel = 6;
    this.#displayMapWhenAtRegistrationDetailsStep();
  }

  disconnect() {
    this.map.remove();
  }

  async locateAddress() {
    const results = await this.provider.search({ query: this.#addressQuery() });
    if (results.length > 0) {
      const result = results[0];
      this.#setLatitudeLongitude(result.y, result.x);
      this.#addMarker(result.y, result.x);
      this.map.setView([result.y, result.x], this.zoomLevel);
      this.confirmAddressFieldTarget.style.display = "block";
      this.dragPinNoteTarget.style.display = "block";
    }
  }

  #addressQuery() {
    const stateField = document.getElementById("enterprise_state");
    const state = stateField.options[stateField.selectedIndex]?.label;
    const countryField = document.getElementById("enterprise_country");
    const country = countryField.options[countryField.selectedIndex]?.label;
    const city = document.getElementById("enterprise_city")?.value;
    const zipcode = document.getElementById("enterprise_zipcode")?.value;
    const addressLine1 = document.getElementById("enterprise_address")?.value;
    const addressLine2 = document.getElementById("enterprise_address2")?.value;

    // If someone clicks the locate address on map button without filling in their address the
    // geocoded address will not be very accurate so don't zoom in too close so it's easier for
    // people to see where the marker is.
    if (!addressLine1 && !city && !zipcode) {
      this.zoomLevel = 6;
    } else {
      this.zoomLevel = 14;
    }

    return [addressLine1, addressLine2, city, state, zipcode, country]
      .filter((value) => !!value)
      .join(", ");
  }

  #addMarker(latitude, longitude) {
    const icon = L.icon({ iconUrl: "/map_icons/map_003-producer-shop.svg" });
    this.marker = L.marker([latitude, longitude], {
      draggable: true,
      icon: icon,
    });

    this.marker.on("dragend", (event) => {
      const position = event.target.getLatLng();
      this.#setLatitudeLongitude(position.lat, position.lng);
    });

    this.marker.addTo(this.map);
  }

  #displayMap() {
    // Don't initialise map in test environment because that could possibly abuse OSM tile servers
    if (process.env.RAILS_ENV == "test") {
      return false;
    }

    this.map = L.map("open-street-map");
    L.tileLayer.provider(this.providerNameValue, this.providerOptionsValue).addTo(this.map);
    this.map.setView([this.defaultLatitudeValue, this.defaultLongitudeValue], this.zoomLevel);
    this.provider = new OpenStreetMapProvider();
  }

  // The connect() method is called before the registration details step is visible, this
  // causes the map tiles to render incorrectly. To fix this only display the map when the
  // registration details step has been reached.
  #displayMapWhenAtRegistrationDetailsStep() {
    const observer = new IntersectionObserver(
      ([intersectionObserverEntry]) => {
        if (intersectionObserverEntry.target.offsetParent !== null) {
          this.#displayMap();
          observer.disconnect();
        }
      },
      { threshold: [0] },
    );
    observer.observe(document.getElementById("registration-details"));
  }

  // The registration process uses Angular, set latitude and longitude data properties so the
  // Angular RegistrationCtrl controller can read and add them to the parameters it uses to create
  // new enterprises.
  #setLatitudeLongitude(latitude, longitude) {
    document.getElementById("open-street-map").dataset.latitude = latitude;
    document.getElementById("open-street-map").dataset.longitude = longitude;
  }
}
