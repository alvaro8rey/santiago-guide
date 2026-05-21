export interface POI {
  id: string;
  nombre: string;
  descripcion: string;
  lat: number;
  lng: number;
  radio_activacion: number;
  imagen_url: string;
  audio_url: string;
  activo: boolean;
  created_at: string;
  updated_at: string;
}

export interface POIFormData {
  nombre: string;
  descripcion: string;
  lat: number;
  lng: number;
  radio_activacion: number;
  imagen_url: string;
  audio_url: string;
  activo: boolean;
  imagen_file?: File;
  audio_file?: File;
}
