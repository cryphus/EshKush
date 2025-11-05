export type Offer = {
  id: string;
  title: string;
  rating: number;
  distanceKm: number;
  time: string;
  oldPrice?: number;
  price: number;
  image: string;
  logo?: string;
};

export const OFFERS: Offer[] = [
  {
    id: "1",
    title: "Пекарня Bazbik",
    rating: 5,
    distanceKm: 1.3,
    time: "19:30 - 21:00",
    oldPrice: 360,
    price: 199,
    image:
      "https://images.unsplash.com/photo-1555507036-ab1f4038808a?q=80&w=1400&auto=format&fit=crop",
    logo: "https://static.rfstat.com/logo-presets/2551/thumbnail_4bc11506be31_1x.webp",
  },
  {
    id: "2",
    title: "Кондитерская Besel",
    rating: 4.8,
    distanceKm: 0.8,
    time: "19:00 - 22:00",
    oldPrice: 340,
    price: 189,
    image:
      "https://images.unsplash.com/photo-1499636136210-6f4ee915583e?q=80&w=1400&auto=format&fit=crop",
    logo: "https://static.rfstat.com/logo-presets/2551/thumbnail_4bc11506be31_1x.webp",
  },
  {
    id: "3",
    title: "Суши-бар Исуси",
    rating: 4.6,
    distanceKm: 3.4,
    time: "21:00 - 23:00",
    oldPrice: 1099,
    price: 600,
    image:
      "https://images.unsplash.com/photo-1555507036-ab1f4038808a?q=80&w=1400&auto=format&fit=crop",
    logo: "https://static.rfstat.com/logo-presets/2551/thumbnail_4bc11506be31_1x.webp",
  },
  {
    id: "4",
    title: "LENKOFF Пироговая",
    rating: 4.5,
    distanceKm: 2.1,
    time: "18:00 - 21:00",
    oldPrice: 420,
    price: 239,
    image:
      "https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=1400&auto=format&fit=crop",
    logo: "https://static.rfstat.com/logo-presets/2551/thumbnail_4bc11506be31_1x.webp",
  },
];
