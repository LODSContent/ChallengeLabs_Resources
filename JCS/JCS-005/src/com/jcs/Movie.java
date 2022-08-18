package com.jcs;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Scanner;
import java.util.stream.Collectors;

public class Movie {
	private String title;
	private List<String> directors;
	private String releaseYear;
	private String rating;
	private int duration;
	private List<String> genres;

	public static List<Movie> getMovieList() {
		List<Movie> movieList = new ArrayList<>();

		try (Scanner scan = new Scanner(new File("resources/disney.txt")).useDelimiter("::")) {
			while (scan.hasNextLine()) {
				String line = scan.nextLine();
				String[] fields = line.split("::");
				movieList.add(
						new Movie(fields[0], fields[1], fields[2], fields[3], Integer.parseInt(fields[4]), fields[5]));
			}
		} catch (IOException e) {
			System.out.println("Error in reading file: " + e);
		}

		return movieList;
	}

	private Movie(String title, String directors, String releaseYear, String rating, int duration, String genres) {
		List<String> localDirectors = Arrays.stream(directors.split(", ")).collect(Collectors.toList());
		List<String> localGenres = Arrays.stream(genres.split(", ")).collect(Collectors.toList());
		this.title = title;
		this.directors = localDirectors;
		this.releaseYear = releaseYear;
		this.rating = rating;
		this.duration = duration;
		this.genres = localGenres;
	}
	
	@Override
	public String toString() {
		return "Movie [title=" + title + ", directors=" + directors + ", releaseYear=" + releaseYear + ", rating="
				+ rating + ", duration=" + duration + "min, genres=" + genres + "]";
	}

	public String getTitle() {
		return title;
	}

	public void setTitle(String title) {
		this.title = title;
	}

	public List<String> getDirectors() {
		return directors;
	}

	public void setDirectors(List<String> directors) {
		this.directors = directors;
	}

	public String getReleaseYear() {
		return releaseYear;
	}

	public void setReleaseYear(String releaseYear) {
		this.releaseYear = releaseYear;
	}

	public String getRating() {
		return rating;
	}

	public void setRating(String rating) {
		this.rating = rating;
	}

	public int getDuration() {
		return duration;
	}

	public void setDuration(int duration) {
		this.duration = duration;
	}

	public List<String> getGenres() {
		return genres;
	}

	public void setGenres(List<String> genres) {
		this.genres = genres;
	}

}
