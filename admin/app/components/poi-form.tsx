'use client';

import { useState, useRef } from 'react';
import Image from 'next/image';
import { POI, POIFormData } from '@/lib/types';
import { supabase } from '@/lib/supabase';

interface POIFormProps {
  poi?: POI;
  onSubmit: (data: POIFormData) => Promise<void>;
  isLoading: boolean;
}

export function POIForm({ poi, onSubmit, isLoading }: POIFormProps) {
  const [formData, setFormData] = useState<POIFormData>({
    nombre: poi?.nombre || '',
    descripcion: poi?.descripcion || '',
    lat: poi?.lat || 0,
    lng: poi?.lng || 0,
    radio_activacion: poi?.radio_activacion || 30,
    imagen_url: poi?.imagen_url || '',
    audio_url: poi?.audio_url || '',
    activo: poi?.activo || true,
  });

  const [imageFile, setImageFile] = useState<File | null>(null);
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState(poi?.imagen_url || '');
  const [geoLoading, setGeoLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const fileInputRef = useRef<HTMLInputElement>(null);
  const audioInputRef = useRef<HTMLInputElement>(null);

  const handleInputChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    const { name, value, type } = e.target as HTMLInputElement;

    if (type === 'checkbox') {
      const checked = (e.target as HTMLInputElement).checked;
      setFormData({ ...formData, [name]: checked });
    } else if (type === 'number') {
      setFormData({ ...formData, [name]: parseFloat(value) });
    } else {
      setFormData({ ...formData, [name]: value });
    }
  };

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setImageFile(file);
      const reader = new FileReader();
      reader.onload = () => {
        setImagePreview(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleAudioChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setAudioFile(file);
    }
  };

  const getGeolocation = async () => {
    setGeoLoading(true);
    try {
      if (!navigator.geolocation) {
        throw new Error('Geolocalización no soportada en este navegador');
      }

      const position = await new Promise<GeolocationPosition>((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(resolve, reject);
      });

      setFormData({
        ...formData,
        lat: position.coords.latitude,
        lng: position.coords.longitude,
      });

      setSuccess('Coordenadas obtenidas correctamente');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al obtener ubicación');
    } finally {
      setGeoLoading(false);
    }
  };

  const uploadFile = async (
    file: File,
    bucket: 'imagenes' | 'audios'
  ): Promise<string> => {
    const timestamp = Date.now();
    const fileName = `${timestamp}-${file.name}`;

    const { error, data } = await supabase.storage
      .from(bucket)
      .upload(fileName, file);

    if (error) throw error;

    const {
      data: { publicUrl },
    } = supabase.storage.from(bucket).getPublicUrl(fileName);

    return publicUrl;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    try {
      let imagen_url = formData.imagen_url;
      let audio_url = formData.audio_url;

      if (imageFile) {
        imagen_url = await uploadFile(imageFile, 'imagenes');
      }

      if (audioFile) {
        audio_url = await uploadFile(audioFile, 'audios');
      }

      await onSubmit({
        ...formData,
        imagen_url,
        audio_url,
      });

      setSuccess('POI guardado correctamente');
      setImageFile(null);
      setAudioFile(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al guardar');
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {error && (
        <div className="rounded-md bg-red-50 p-4">
          <div className="text-sm font-medium text-red-800">{error}</div>
        </div>
      )}

      {success && (
        <div className="rounded-md bg-green-50 p-4">
          <div className="text-sm font-medium text-green-800">{success}</div>
        </div>
      )}

      {/* Nombre */}
      <div>
        <label htmlFor="nombre" className="block text-sm font-medium text-gray-700">
          Nombre
        </label>
        <input
          type="text"
          name="nombre"
          id="nombre"
          required
          value={formData.nombre}
          onChange={handleInputChange}
          className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
        />
      </div>

      {/* Descripción */}
      <div>
        <label htmlFor="descripcion" className="block text-sm font-medium text-gray-700">
          Descripción
        </label>
        <textarea
          name="descripcion"
          id="descripcion"
          rows={4}
          required
          value={formData.descripcion}
          onChange={handleInputChange}
          className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
        />
      </div>

      {/* Coordenadas */}
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="lat" className="block text-sm font-medium text-gray-700">
            Latitud
          </label>
          <input
            type="number"
            name="lat"
            id="lat"
            step="0.000001"
            required
            value={formData.lat}
            onChange={handleInputChange}
            className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          />
        </div>
        <div>
          <label htmlFor="lng" className="block text-sm font-medium text-gray-700">
            Longitud
          </label>
          <input
            type="number"
            name="lng"
            id="lng"
            step="0.000001"
            required
            value={formData.lng}
            onChange={handleInputChange}
            className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          />
        </div>
      </div>

      {/* Botón geolocalización */}
      <button
        type="button"
        onClick={getGeolocation}
        disabled={geoLoading}
        className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md shadow-sm text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
      >
        {geoLoading ? 'Obteniendo ubicación...' : 'Obtener mis coordenadas'}
      </button>

      {/* Radio de activación */}
      <div>
        <label htmlFor="radio_activacion" className="block text-sm font-medium text-gray-700">
          Radio de activación (metros)
        </label>
        <input
          type="number"
          name="radio_activacion"
          id="radio_activacion"
          min="1"
          required
          value={formData.radio_activacion}
          onChange={handleInputChange}
          className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
        />
      </div>

      {/* Imagen */}
      <div>
        <label htmlFor="imagen" className="block text-sm font-medium text-gray-700">
          Imagen
        </label>
        {imagePreview && (
          <div className="mt-2 mb-4">
            <img
              src={imagePreview}
              alt="Preview"
              width={200}
              height={200}
              className="rounded-md object-cover"
            />
          </div>
        )}
        <input
          type="file"
          id="imagen"
          accept="image/*"
          onChange={handleImageChange}
          ref={fileInputRef}
          className="mt-1 block w-full"
        />
      </div>

      {/* Audio */}
      <div>
        <label htmlFor="audio" className="block text-sm font-medium text-gray-700">
          Audio
        </label>
        {formData.audio_url && !audioFile && (
          <div className="mt-2 mb-4">
            <audio controls className="w-full">
              <source src={formData.audio_url} type="audio/mpeg" />
            </audio>
          </div>
        )}
        <input
          type="file"
          id="audio"
          accept="audio/*"
          onChange={handleAudioChange}
          ref={audioInputRef}
          className="mt-1 block w-full"
        />
        {audioFile && <p className="text-sm text-gray-600 mt-2">Nuevo audio: {audioFile.name}</p>}
      </div>

      {/* Activo */}
      <div className="flex items-center">
        <input
          type="checkbox"
          name="activo"
          id="activo"
          checked={formData.activo}
          onChange={handleInputChange}
          className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
        />
        <label htmlFor="activo" className="ml-2 block text-sm text-gray-700">
          Activo
        </label>
      </div>

      {/* Botones */}
      <div className="flex justify-between">
        <a
          href="/"
          className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md shadow-sm text-gray-700 bg-white hover:bg-gray-50"
        >
          Cancelar
        </a>
        <button
          type="submit"
          disabled={isLoading}
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
        >
          {isLoading ? 'Guardando...' : 'Guardar POI'}
        </button>
      </div>
    </form>
  );
}
